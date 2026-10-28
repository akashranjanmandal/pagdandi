import 'dart:async';

import 'package:core_model/core_model.dart';
import 'package:flutter/services.dart';
import 'package:native_bridge/src/generated/native_api.g.dart';

/// The single receiver of native callbacks. The platform channel can only
/// have one handler, so this hub fans events out as streams that the port
/// adapters subscribe to.
class NativeEvents implements PagdandiFlutterApi {
  final _battery = StreamController<int>.broadcast(sync: true);
  final _sms = StreamController<SmsReport>.broadcast(sync: true);
  final _signal = StreamController<SignalState>.broadcast(sync: true);
  final _locations = StreamController<LocationFix>.broadcast(sync: true);
  // Single-subscription: commands arriving before the bridge listens are
  // buffered, not lost (the relay flushes its queue the moment the core
  // registers).
  final _commands = StreamController<String>();
  final _states = StreamController<String>.broadcast(sync: true);
  final _alarms = StreamController<int>.broadcast(sync: true);
  final _accel = StreamController<List<AccelSample>>.broadcast(sync: true);

  /// Fixes dropped because their values were impossible.
  int droppedFixes = 0;

  /// Registers this hub as the native callback handler.
  void install({BinaryMessenger? binaryMessenger}) =>
      PagdandiFlutterApi.setUp(this, binaryMessenger: binaryMessenger);

  /// Battery levels in percent.
  Stream<int> get battery => _battery.stream;

  /// SMS progress reports.
  Stream<SmsReport> get smsReports => _sms.stream;

  /// Mobile signal changes.
  Stream<SignalState> get signal => _signal.stream;

  /// GPS fixes, oldest first.
  Stream<LocationFix> get locations => _locations.stream;

  /// Core engine: commands from the UI (buffered until listened to).
  Stream<String> get commands => _commands.stream;

  /// UI engine: states from the core.
  Stream<String> get states => _states.stream;

  /// Exact alarms that fired.
  Stream<int> get alarms => _alarms.stream;

  /// Accelerometer sample batches, oldest first.
  Stream<List<AccelSample>> get accelerometer => _accel.stream;

  @override
  void onBatteryLevel(int level) => _battery.add(level);

  @override
  void onSmsReport(String id, SmsStatusDto status) => _sms.add(
    SmsReport(
      id: id,
      status: switch (status) {
        SmsStatusDto.sending => SmsStatus.sending,
        SmsStatusDto.sent => SmsStatus.sent,
        SmsStatusDto.delivered => SmsStatus.delivered,
        SmsStatusDto.failed => SmsStatus.failed,
      },
    ),
  );

  @override
  void onSignalState(SignalStateDto state) => _signal.add(signalFromDto(state));

  @override
  void onCommand(String json) => _commands.add(json);

  @override
  void onState(String json) => _states.add(json);

  @override
  void onAlarm(int id) => _alarms.add(id);

  @override
  void onAccelerometer(List<double> batch) {
    // Flat [x, y, z, timeMs] groups. A damaged batch is dropped whole: half a
    // reading must never look like a fall.
    if (batch.isEmpty ||
        batch.length % 4 != 0 ||
        !batch.every((v) => v.isFinite)) {
      return;
    }
    _accel.add([
      for (var i = 0; i < batch.length; i += 4)
        AccelSample(
          x: batch[i],
          y: batch[i + 1],
          z: batch[i + 2],
          at: Duration(milliseconds: batch[i + 3].round()),
        ),
    ]);
  }

  @override
  void onLocations(List<LocationFixDto> fixes) {
    for (final f in fixes) {
      final ok =
          f.latitude.isFinite &&
          f.longitude.isFinite &&
          f.accuracyM.isFinite &&
          f.latitude >= -90 &&
          f.latitude <= 90 &&
          f.longitude >= -180 &&
          f.longitude <= 180 &&
          f.accuracyM >= 0;
      if (!ok) {
        droppedFixes++;
        continue;
      }
      _locations.add(
        LocationFix(
          latitude: f.latitude,
          longitude: f.longitude,
          accuracyM: f.accuracyM,
          gpsTime: DateTime.fromMillisecondsSinceEpoch(f.timeMs, isUtc: true),
          altitudeM: f.altitudeM,
          speedMps: f.speedMps,
          bearingDeg: f.bearingDeg,
        ),
      );
    }
  }
}

/// Maps the native signal state to the core one.
SignalState signalFromDto(SignalStateDto state) => switch (state) {
  SignalStateDto.noService => SignalState.noService,
  SignalStateDto.emergencyOnly => SignalState.emergencyOnly,
  SignalStateDto.inService => SignalState.inService,
};
