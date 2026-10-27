import 'dart:async';

import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter/services.dart';
import 'package:native_bridge/src/generated/native_api.g.dart';

/// [BatteryMonitor] backed by the Android battery manager.
class NativeBatteryMonitor implements BatteryMonitor, PagdandiFlutterApi {
  NativeBatteryMonitor._(this._level);

  /// Reads the current level from [host] and starts receiving updates.
  static Future<NativeBatteryMonitor> create(
    PagdandiHostApi host, {
    BinaryMessenger? binaryMessenger,
  }) async {
    final monitor = NativeBatteryMonitor._(
      _clamp(await host.batteryLevel()),
    );
    PagdandiFlutterApi.setUp(monitor, binaryMessenger: binaryMessenger);
    return monitor;
  }

  static int _clamp(int v) => v.clamp(0, 100);

  final _changes = StreamController<int>.broadcast(sync: true);
  int _level;

  @override
  int get level => _level;

  @override
  Stream<int> get changes => _changes.stream;

  @override
  void onBatteryLevel(int level) {
    _level = _clamp(level);
    _changes.add(_level);
  }
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
