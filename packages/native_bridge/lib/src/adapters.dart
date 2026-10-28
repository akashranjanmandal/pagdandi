import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:native_bridge/src/generated/native_api.g.dart';
import 'package:native_bridge/src/native_events.dart';

/// [BatteryMonitor] backed by the Android battery manager.
class NativeBatteryMonitor implements BatteryMonitor {
  NativeBatteryMonitor._(this._level, Stream<int> source) {
    source.listen((v) {
      _level = _clamp(v);
      _changes.add(_level);
    });
  }

  /// Reads the current level from [host] and follows [events].
  static Future<NativeBatteryMonitor> create(
    PagdandiHostApi host,
    NativeEvents events,
  ) async =>
      NativeBatteryMonitor._(_clamp(await host.batteryLevel()), events.battery);

  static int _clamp(int v) => v.clamp(0, 100);

  final _changes = StreamController<int>.broadcast(sync: true);
  int _level;

  @override
  int get level => _level;

  @override
  Stream<int> get changes => _changes.stream;
}

/// [SmsGateway] that sends through the Android radio and relays its reports.
class NativeSmsGateway implements SmsGateway {
  /// Creates the gateway.
  NativeSmsGateway(this._host, this._events);

  final PagdandiHostApi _host;
  final NativeEvents _events;

  @override
  Stream<SmsReport> get reports => _events.smsReports;

  @override
  Future<void> send(SmsMessage message) =>
      _host.sendSms(message.id, message.to, message.body);
}

/// [SignalMonitor] backed by the Android telephony service state.
class NativeSignalMonitor implements SignalMonitor {
  NativeSignalMonitor._(this._current, Stream<SignalState> source) {
    source.listen((s) {
      _current = s;
      _changes.add(s);
    });
  }

  /// Reads the current state from [host] and follows [events].
  static Future<NativeSignalMonitor> create(
    PagdandiHostApi host,
    NativeEvents events,
  ) async => NativeSignalMonitor._(
    signalFromDto(await host.signalState()),
    events.signal,
  );

  final _changes = StreamController<SignalState>.broadcast(sync: true);
  SignalState _current;

  @override
  SignalState get current => _current;

  @override
  Stream<SignalState> get changes => _changes.stream;
}

/// [LocationSource] backed by the fused location provider (or plain GPS).
class NativeLocationSource implements LocationSource {
  /// Creates the source.
  NativeLocationSource(this._host, this._events);

  final PagdandiHostApi _host;
  final NativeEvents _events;

  @override
  Stream<LocationFix> get fixes => _events.locations;

  @override
  Future<void> request(LocationRequest request) => _host.startLocation(
    LocationRequestDto(
      intervalMs: request.interval.inMilliseconds,
      maxBatchDelayMs: request.maxBatchDelay.inMilliseconds,
      minDistanceM: request.minDistanceM,
    ),
  );

  @override
  Future<void> stop() => _host.stopLocation();
}

/// The core's end of the UI/core channel, over the native relay.
class NativeCoreChannel implements CoreChannel {
  /// Creates the channel.
  NativeCoreChannel(this._host, this._events);

  final PagdandiHostApi _host;
  final NativeEvents _events;

  @override
  Stream<String> get commands => _events.commands;

  @override
  Future<void> publish(String json) => _host.publishState(json);

  /// Tells the relay this engine is the core. Call it AFTER the bridge
  /// listens to [commands], so queued commands are not missed.
  Future<void> register() => _host.setRole('core');
}

/// The UI's end of the UI/core channel, over the native relay.
class NativeUiChannel implements UiChannel {
  /// Creates the channel.
  NativeUiChannel(this._host, this._events);

  final PagdandiHostApi _host;
  final NativeEvents _events;

  @override
  Stream<String> get states => _events.states;

  @override
  Future<void> send(String json) => _host.sendCommand(json);

  /// Tells the relay this engine is the UI. Call it AFTER listening to
  /// [states]; the relay then sends the latest state at once.
  Future<void> register() => _host.setRole('ui');
}

/// [HeartbeatSink] that tells the native safety guard the core is alive.
class NativeHeartbeatSink implements HeartbeatSink {
  /// Creates the sink.
  NativeHeartbeatSink(this._host);

  final PagdandiHostApi _host;

  @override
  Future<void> beat(DateTime at) => _host.heartbeat(at.millisecondsSinceEpoch);
}

/// [TrekService] backed by the Android foreground service.
class NativeTrekService implements TrekService {
  /// Creates the control.
  NativeTrekService(this._host);

  final PagdandiHostApi _host;

  @override
  Future<void> start() => _host.startTrekService();

  @override
  Future<void> stop() => _host.stopTrekService();
}

/// [HapticOutput] that plays the vocabulary on the phone's vibrator.
class NativeHapticOutput implements HapticOutput {
  /// Creates the adapter over [_host].
  NativeHapticOutput(this._host);

  final PagdandiHostApi _host;

  @override
  Future<void> play(HapticPattern pattern) => _host.playHaptic(
    HapticRequest(
      timings: pattern.waveform,
      repeat: pattern.repeats,
      strong: pattern.strong,
    ),
  );

  @override
  Future<void> cancel() => _host.cancelHaptic();
}

/// Maps the native capability report to the beacon port's capabilities.
BeaconCapabilities beaconCapabilitiesFrom(DeviceCapabilities caps) =>
    BeaconCapabilities(
      codedPhy: caps.leCodedPhySupported,
      extendedAdvertising: caps.leExtendedAdvertisingSupported,
    );

/// [TorchOutput] on the camera flash. Never throws: a busy camera is not an
/// emergency of its own.
class NativeTorchOutput implements TorchOutput {
  /// Creates the output.
  NativeTorchOutput(this._host);

  final PagdandiHostApi _host;

  @override
  Future<void> setOn({required bool on}) =>
      _safely(() => _host.setTorch(on, false));

  @override
  Future<void> setStrobe({required bool on}) =>
      _safely(() => _host.setTorch(on, true));
}

/// [SirenOutput] on the alarm stream.
class NativeSirenOutput implements SirenOutput {
  /// Creates the output.
  NativeSirenOutput(this._host);

  final PagdandiHostApi _host;

  @override
  Future<void> setOn({required bool on}) => _safely(() => _host.setSiren(on));
}

/// Opens the phone dialer with a number filled in; the person presses call.
class NativeDialer implements Dialer {
  /// Creates the dialer.
  NativeDialer(this._host);

  final PagdandiHostApi _host;

  @override
  Future<void> open(String number) => _safely(() => _host.openDialer(number));
}

/// [AlarmScheduler] on Android exact alarms (fire in Doze, wake a dead
/// process). The core thinks in trusted (GPS) time; Android alarms use the
/// phone clock, so the delay is converted.
class NativeAlarmScheduler implements AlarmScheduler {
  /// Creates the scheduler.
  NativeAlarmScheduler(
    this._host,
    NativeEvents events,
    this._trusted,
    this._system,
  ) {
    events.alarms.listen(_fired.add);
  }

  final PagdandiHostApi _host;
  final TrustedClock _trusted;
  final Clock _system;
  final _fired = StreamController<int>.broadcast(sync: true);

  @override
  Stream<int> get fired => _fired.stream;

  @override
  Future<void> schedule(int id, DateTime at) {
    final delay = at.difference(_trusted.now().time);
    final atMs = _system
        .now()
        .add(delay.isNegative ? Duration.zero : delay)
        .millisecondsSinceEpoch;
    return _host.scheduleAlarm(id, atMs);
  }

  @override
  Future<void> cancel(int id) => _host.cancelAlarm(id);

  /// Delivers alarms that fired while the core was not running. Call after
  /// listening to [fired].
  Future<void> replayMissed() async {
    try {
      (await _host.takeFiredAlarms()).forEach(_fired.add);
    } on Object {
      // Nothing to replay is the safe reading.
    }
  }
}

Future<void> _safely(Future<void> Function() call) async {
  try {
    await call();
  } on Object {
    // A hardware helper failing must never break the caller.
  }
}

/// [Accelerometer] on the phone's sensor. The sensor runs only while the
/// stream is listened to. A phone without one, or a failing host, simply
/// gives an empty stream: no fall detection, never a crash.
class NativeAccelerometer implements Accelerometer {
  /// Creates the adapter.
  NativeAccelerometer(this._host, this._events);

  final PagdandiHostApi _host;
  final NativeEvents _events;

  @override
  Stream<AccelSample> samples(Duration period) {
    late StreamController<AccelSample> out;
    StreamSubscription<List<AccelSample>>? sub;
    out = StreamController<AccelSample>(
      sync: true,
      onListen: () async {
        sub = _events.accelerometer.listen((batch) => batch.forEach(out.add));
        try {
          final ok = await _host.startAccelerometer(period.inMilliseconds);
          if (!ok) await out.close();
        } on Object {
          await out.close();
        }
      },
      onCancel: () async {
        await sub?.cancel();
        await _safely(_host.stopAccelerometer);
      },
    );
    return out.stream;
  }
}

/// [VoiceOutput] on Android TextToSpeech. Never throws: a speaker that cannot
/// speak must not break the caller.
class NativeVoiceOutput implements VoiceOutput {
  /// Creates the output.
  NativeVoiceOutput(this._host);

  final PagdandiHostApi _host;

  @override
  Future<void> speak(String text, {bool urgent = false}) =>
      _safely(() => _host.speak(text, urgent));

  @override
  Future<void> stop() => _safely(_host.stopSpeaking);
}
