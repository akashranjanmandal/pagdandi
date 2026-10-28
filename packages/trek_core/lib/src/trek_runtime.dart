import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:meta/meta.dart';

/// Ids of the exact alarms the runtime uses.
abstract final class AlarmIds {
  /// Ends the fall countdown.
  static const int fall = 1;
}

/// An effect (or storage write) failed. Everything else carried on.
@immutable
class HealthWarning {
  /// Creates a warning.
  const HealthWarning({
    required this.source,
    required this.error,
    required this.at,
  });

  /// What failed, e.g. "Haptic" or "snapshot".
  final String source;

  /// The error.
  final Object error;

  /// When.
  final DateTime at;
}

/// One serialized queue of events in, state snapshots and effects out.
///
/// Every transition is persisted before its effects run, so a crash between
/// the two is repaired on restart. Effects run safety-first, each isolated so
/// a failing vibrator or Bluetooth never stops an SOS.
class TrekRuntime {
  /// Creates the runtime.
  TrekRuntime({
    required this._clock,
    required this._snapshots,
    required this._sos,
    required this._haptics,
    required this._beacon,
    required this._alarms,
    required this._tracking,
    required this._battery,
    required Logger logger,
    required String memberName,
    required this._contacts,
    this._trackingRequest = const LocationRequest(
      interval: Duration(seconds: 5),
    ),
  }) : _log = logger,
       _name = memberName;

  final TrustedClock _clock;
  final SnapshotStore _snapshots;
  final SosKernel _sos;
  final HapticOutput _haptics;
  final BeaconTransport _beacon;
  final AlarmScheduler _alarms;
  final TrackingPipeline _tracking;
  final BatteryMonitor _battery;
  final Logger _log;
  final String _name;
  final List<String> Function() _contacts;
  final LocationRequest _trackingRequest;

  static const _tag = 'runtime';

  TrekState _state = TrekState.idle;
  Future<void> _tail = Future<void>.value();
  StreamSubscription<int>? _alarmSub;
  final _states = StreamController<TrekState>.broadcast(sync: true);
  final _ui = StreamController<Effect>.broadcast(sync: true);
  final _warnings = StreamController<HealthWarning>.broadcast(sync: true);

  /// The current state.
  TrekState get state => _state;

  /// State after every transition.
  Stream<TrekState> get states => _states.stream;

  /// Screens the UI engine must show (fall countdown, friend alert).
  Stream<Effect> get uiCommands => _ui.stream;

  /// Failures the runtime survived.
  Stream<HealthWarning> get warnings => _warnings.stream;

  /// SOS delivery progress, live.
  Stream<SosSummary> get sosSummary => _sos.summary;

  /// SOS delivery progress now.
  SosSummary get sosCurrent => _sos.current;

  Future<T> _serial<T>(Future<T> Function() job) {
    final done = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        done.complete(await job());
      } on Object catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }

  /// Restores the last state, resumes whatever was running, and starts
  /// listening for the fall alarm. Call once per process start.
  Future<void> start() => _serial(() async {
    _state = await _restore();
    await _sos.start();
    if (_sos.current.active && _state.emergency is! SosActive) {
      // The outbox is the truth: an SOS there must never be forgotten.
      _state = _state.copyWith(emergency: const SosActive());
      await _persist();
    }
    _alarmSub = _alarms.fired.listen((id) {
      if (id == AlarmIds.fall) {
        unawaited(dispatch(const FallCountdownExpired()));
      }
    });
    _states.add(_state);
    await _resume();
  });

  /// Feeds one event through the reducer. Events are handled one at a time,
  /// in the order dispatched.
  Future<void> dispatch(TrekEvent event) => _serial(() => _apply(event));

  /// Stops listening. Stored state is untouched.
  void dispose() {
    unawaited(_alarmSub?.cancel());
    _sos.dispose();
    unawaited(_states.close());
    unawaited(_ui.close());
    unawaited(_warnings.close());
  }

  Future<TrekState> _restore() async {
    try {
      final json = await _snapshots.latest();
      if (json != null) {
        final s = decodeSnapshot(json);
        if (s != null) return s;
        _log.error(_tag, 'snapshot not understood, starting idle');
      }
    } on Object catch (e) {
      _log.error(_tag, 'could not read the snapshot, starting idle', error: e);
    }
    return TrekState.idle;
  }

  Future<void> _persist() async {
    try {
      await _snapshots.save(encodeSnapshot(_state), at: _clock.now().time);
    } on Object catch (e) {
      _log.error(_tag, 'snapshot write failed, continuing', error: e);
      _warn('snapshot', e);
    }
  }

  Future<void> _apply(TrekEvent event) async {
    final t = reduce(_state, event, _clock.now().time);
    if (t.state == _state && t.effects.isEmpty) return;
    final changed = t.state != _state;
    _state = t.state;
    if (changed) {
      await _persist();
      _states.add(_state);
    }
    await _run(t.effects);
  }

  /// Re-applies the steady effects of the restored state.
  Future<void> _resume() async {
    final now = _clock.now().time;
    final effects = <Effect>[
      if (_state.activity != Activity.idle) const StartTracking(),
      ...switch (_state.emergency) {
        NoEmergency() => const <Effect>[],
        LostMode() => const [BeaconOn()],
        SosActive() => [
          if (!_sos.current.active) const RaiseSos(),
          const BeaconOn(),
          const Haptic(HapticPattern.sos),
        ],
        FriendSos(:final friendId) => [
          const Haptic(HapticPattern.sos),
          ShowFriendScreen(friendId),
        ],
        FallCountdown(:final deadline) =>
          deadline.isAfter(now)
              ? [ScheduleFallDeadline(deadline), const ShowFallScreen()]
              : const <Effect>[],
      },
    ];
    await _run(effects);
    final e = _state.emergency;
    if (e is FallCountdown && !e.deadline.isAfter(now)) {
      // The deadline passed while the phone was off: fail safe, send the SOS.
      await _apply(const FallCountdownExpired());
    }
  }

  static int _priority(Effect e) => switch (e) {
    RaiseSos() || ArmSos() || CancelSos() || DisarmSos() => 0,
    BeaconOn() || BeaconOff() || Haptic() || CancelHaptic() => 1,
    ScheduleFallDeadline() || CancelFallDeadline() => 2,
    StartTracking() || StopTracking() => 3,
    ShowFallScreen() || ShowFriendScreen() => 4,
  };

  Future<void> _run(List<Effect> effects) async {
    final indexed = [for (var i = 0; i < effects.length; i++) (i, effects[i])]
      ..sort((a, b) {
        final c = _priority(a.$2).compareTo(_priority(b.$2));
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    for (final (_, e) in indexed) {
      try {
        await _do(e);
      } on Object catch (err) {
        _log.error(_tag, 'effect ${e.runtimeType} failed', error: err);
        _warn(e.runtimeType.toString(), err);
      }
    }
  }

  void _warn(String source, Object error) => _warnings.add(
    HealthWarning(source: source, error: error, at: _clock.now().time),
  );

  SosReport _report() => SosReport(
    name: _name,
    fix: _tracking.breadcrumb.isEmpty ? null : _tracking.breadcrumb.last,
    time: _clock.now(),
    batteryPercent: _battery.level,
  );

  Uint8List _beaconPayload() {
    final f = _tracking.breadcrumb.isEmpty ? null : _tracking.breadcrumb.last;
    final text = f == null ? _name : '$_name|${f.latitude},${f.longitude}';
    return Uint8List.fromList(utf8.encode(text));
  }

  Future<void> _do(Effect e) async {
    switch (e) {
      case RaiseSos() || ArmSos():
        await _sos.raise(report: _report(), contacts: _contacts());
      case CancelSos() || DisarmSos():
        await _sos.cancel(name: _name);
      case BeaconOn():
        await _beacon.startBeacon(_beaconPayload());
      case BeaconOff():
        await _beacon.stopBeacon();
      case Haptic(:final pattern):
        await _haptics.play(pattern);
      case CancelHaptic():
        await _haptics.cancel();
      case ScheduleFallDeadline(:final at):
        await _alarms.schedule(AlarmIds.fall, at);
      case CancelFallDeadline():
        await _alarms.cancel(AlarmIds.fall);
      case StartTracking():
        await _tracking.start(_trackingRequest);
      case StopTracking():
        await _tracking.stop();
      case ShowFallScreen() || ShowFriendScreen():
        _ui.add(e);
    }
  }
}
