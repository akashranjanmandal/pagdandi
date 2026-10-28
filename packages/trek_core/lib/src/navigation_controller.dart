import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_geo/core_geo.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:trek_core/src/protocol.dart';

/// Guidance along a loaded route, inside the headless core: feeds accepted
/// fixes to the tracker, plays the navigation haptics (never over an SOS or
/// fall) and notices when GPS goes quiet.
class NavigationController {
  /// Creates the controller. The clock is trusted time; emergencyActive says
  /// whether an SOS or fall owns the vibration motor.
  NavigationController({
    required Stream<LocationFix> fixes,
    required this._haptics,
    required this._clock,
    required Logger logger,
    required bool Function() emergencyActive,
    this._voice,
    Duration tick = const Duration(seconds: 10),
  }) : _log = logger,
       _emergency = emergencyActive {
    _sub = fixes.listen(_onFix);
    _timer = Timer.periodic(tick, (_) => _onTick());
  }

  final HapticOutput _haptics;
  final VoiceOutput? _voice;
  var _arrivedSaid = false;
  final DateTime Function() _clock;
  final Logger _log;
  final bool Function() _emergency;
  late final StreamSubscription<LocationFix> _sub;
  late final Timer _timer;
  final _changes = StreamController<NavView?>.broadcast(sync: true);

  NavigationTracker? _tracker;
  NavView? _view;
  NavStatus? _status;
  var _ownsRepeating = false;
  DateTime? _snoozedUntil;
  GeoPoint? _lastPos;
  double? _heading;

  static const _tag = 'nav';

  /// The route being followed, or null on a free trek.
  Route? get route => _tracker?.route;

  /// Guidance after the latest fix, or null before one / without a route.
  NavView? get view => _view;

  /// A new view (or null when guidance ends).
  Stream<NavView?> get changes => _changes.stream;

  /// Starts following [route], or stops with null.
  void setRoute(Route? route, {bool reversed = false}) {
    _stopOwnBuzz();
    _snoozedUntil = null;
    _arrivedSaid = false;
    _tracker = route == null ? null : NavigationTracker(route);
    if (reversed) _tracker?.reverse();
    _status = null;
    _view = null;
    _lastPos = null;
    _heading = null;
    _changes.add(null);
  }

  /// Walks the same trail the other way (the way home).
  void reverse() {
    final t = _tracker;
    if (t == null) return;
    _stopOwnBuzz();
    t.reverse();
    _arrivedSaid = false;
    _status = null;
    _view = null;
    _changes.add(null);
  }

  /// Silences off-route alerts for [d] ("I know, exploring"). A wrong way or
  /// lost GPS is not silenced.
  void snooze(Duration d) {
    if (_tracker == null) return;
    _snoozedUntil = _clock().add(d);
    _stopOwnBuzz();
    _refresh();
  }

  /// Brings the alerts back; an ongoing off-route state buzzes again.
  void resumeAlerts() {
    if (_snoozedUntil == null) return;
    _snoozedUntil = null;
    _refresh();
    if (_status == NavStatus.offRoute && !_emergency()) {
      _ownsRepeating = true;
      unawaited(_play(HapticPattern.offRoute));
    }
  }

  bool get _snoozed {
    final u = _snoozedUntil;
    return u != null && _clock().isBefore(u);
  }

  /// Rebuilds the view (for a snooze change) and tells listeners.
  void _refresh() {
    final s = _tracker?.current;
    if (s == null) return;
    _view = _build(s);
    _changes.add(_view);
  }

  void _onFix(LocationFix f) {
    final t = _tracker;
    if (t == null) return;
    final pos = GeoPoint(f.latitude, f.longitude);
    _heading = _headingFrom(f, pos);
    _lastPos = pos;
    final s = t.onFix(
      NavFix(position: pos, accuracyM: f.accuracyM, time: f.gpsTime),
    );
    if (s != null) _apply(s);
  }

  double? _headingFrom(LocationFix f, GeoPoint pos) {
    final b = f.bearingDeg;
    if ((f.speedMps ?? 0) > 0.5 && b != null) return b;
    final last = _lastPos;
    if (last != null && distanceM(last, pos) >= 5) {
      return bearingDeg(last, pos);
    }
    return _heading;
  }

  void _onTick() {
    final s = _tracker?.onTick(_clock());
    if (s != null) _apply(s);
    final until = _snoozedUntil;
    if (until != null && !_clock().isBefore(until)) {
      // The snooze ended by itself: an off-route walker is buzzed again.
      resumeAlerts();
    }
  }

  NavView _build(NavSnapshot s) {
    final t = _tracker!;
    final next = s.nextCheckpoint;
    return NavView(
      routeId: t.route.id,
      routeName: t.route.name,
      status: s.status,
      progressM: s.progressM,
      remainingM: s.remainingM,
      totalM: s.totalM,
      crossTrackM: s.crossTrackM,
      bearingToGoDeg: s.bearingToGoDeg,
      headingDeg: _heading,
      arrived: s.arrived,
      reversed: t.isReversed,
      climbLeftM: t.route.climbRemainingM(s.progressM),
      nextName: next?.name,
      nextDistM: s.distanceToCheckpointM,
      reachedName: s.reachedCheckpoint?.name,
      snoozedUntil: _snoozed ? _snoozedUntil : null,
    );
  }

  void _apply(NavSnapshot s) {
    _view = _build(s);
    final before = _status;
    _status = s.status;
    if (before != s.status) _onStatus(before, s.status);
    final reached = s.reachedCheckpoint;
    if (reached != null) {
      unawaited(_play(HapticPattern.checkpoint));
      unawaited(_say('${_short(reached.name)} reached.'));
    }
    if (s.arrived && !_arrivedSaid) {
      _arrivedSaid = true;
      unawaited(_say('You have arrived at ${_endName(_tracker!.route)}.'));
    }
    _changes.add(_view);
  }

  void _onStatus(NavStatus? before, NavStatus now) {
    if (before == NavStatus.offRoute && now != NavStatus.offRoute) {
      _stopOwnBuzz();
      if (now == NavStatus.onRoute) unawaited(_say('Back on the trail.'));
    }
    if (before == NavStatus.gpsLost && now != NavStatus.gpsLost) {
      unawaited(_say('GPS is back.'));
    }
    switch (now) {
      case NavStatus.offRoute:
        if (_snoozed) break;
        if (!_emergency()) _ownsRepeating = true;
        unawaited(_play(HapticPattern.offRoute));
        final m = (_view?.crossTrackM ?? 0).round();
        unawaited(
          _say('Warning. You are $m metres off the trail. Stop and check.'),
        );
      case NavStatus.wrongWay:
        unawaited(_play(HapticPattern.wrongWay));
        unawaited(
          _say(
            _tracker?.isReversed ?? false
                ? 'You are heading the wrong way. Turn around to continue.'
                : 'You are heading back to the start. Turn around to continue.',
          ),
        );
      case NavStatus.gpsLost:
        unawaited(_play(HapticPattern.gpsLost));
        unawaited(_say('GPS signal weak. Keep to the trail.'));
      case NavStatus.onRoute:
        break;
    }
  }

  static String _short(String name) =>
      name.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '').trim();

  /// The name of where the route ends: a named place within 100 m of the end,
  /// else the route itself.
  static String _endName(Route r) {
    final cps = r.checkpoints;
    if (cps.isNotEmpty && cps.last.distanceAlongM >= r.totalM - 100) {
      return _short(cps.last.name);
    }
    return r.name;
  }

  /// Speaks, unless an SOS or fall owns the speaker. Never throws.
  Future<void> _say(String text) async {
    final v = _voice;
    if (v == null || _emergency()) return;
    await _guard(() => v.speak(text));
  }

  /// Ends the off-route buzz, but only if it is ours and no SOS has taken over
  /// the motor in the meantime.
  void _stopOwnBuzz() {
    if (!_ownsRepeating) return;
    _ownsRepeating = false;
    if (_emergency()) return;
    unawaited(_guard(_haptics.cancel));
  }

  Future<void> _play(HapticPattern p) async {
    if (_emergency()) return;
    await _guard(() => _haptics.play(p));
  }

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on Object catch (e) {
      _log.warn(_tag, 'haptic failed, guidance continues', error: e);
    }
  }

  /// Stops listening and ticking.
  void dispose() {
    unawaited(_sub.cancel());
    _timer.cancel();
    unawaited(_changes.close());
  }
}
