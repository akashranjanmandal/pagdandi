import 'dart:async';
import 'dart:typed_data';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';

/// Keeps the latest GPS time reading so [TrustedClock] can use GPS time.
/// Feed it every raw fix.
class GpsTimeTracker implements GpsTimeSource {
  /// Creates a tracker stamping readings with [_clock]'s monotonic time.
  GpsTimeTracker(this._clock);

  final Clock _clock;
  GpsTimeReading? _latest;

  @override
  GpsTimeReading? get latest => _latest;

  /// Records the GPS time of [fix].
  void observe(LocationFix fix) => _latest = GpsTimeReading(
    gpsTime: fix.gpsTime,
    monotonicAtReading: _clock.elapsed(),
  );
}

/// Beacon placeholder until the native BLE beacon exists. It fails loudly
/// (the runtime reports a health warning) rather than pretending to work.
class UnavailableBeaconTransport implements BeaconTransport {
  final _sightings = StreamController<BeaconSighting>.broadcast();

  @override
  BeaconCapabilities get capabilities =>
      const BeaconCapabilities(codedPhy: false, extendedAdvertising: false);

  @override
  Stream<BeaconSighting> get sightings => _sightings.stream;

  @override
  Future<void> startBeacon(Uint8List payload) =>
      Future.error(StateError('BLE beacon is not implemented yet'));

  @override
  Future<void> stopBeacon() async {}

  @override
  Future<void> startScan() =>
      Future.error(StateError('BLE scanning is not implemented yet'));

  @override
  Future<void> stopScan() async {}
}
