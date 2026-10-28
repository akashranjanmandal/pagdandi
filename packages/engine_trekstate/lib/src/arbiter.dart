import 'dart:math' as math;

import 'package:core_ports/core_ports.dart';
import 'package:meta/meta.dart';

/// What one engine needs from the hardware.
@immutable
class Demand {
  /// Creates a demand; every field defaults to "not needed".
  const Demand({
    this.gpsInterval,
    this.allowBatching = false,
    this.maxBatchDelay = Duration.zero,
    this.accelerometerPeriod,
    this.barometer = false,
    this.motion = false,
    this.discovery = false,
  });

  /// Desired time between GPS fixes, or null if GPS is not needed.
  final Duration? gpsInterval;

  /// Whether fixes may be batched (held back to save battery).
  final bool allowBatching;

  /// Longest this engine tolerates fixes being held back.
  final Duration maxBatchDelay;

  /// Desired accelerometer sampling period, or null.
  final Duration? accelerometerPeriod;

  /// Barometer needed.
  final bool barometer;

  /// Significant-motion trigger needed.
  final bool motion;

  /// Peer discovery needed (radio).
  final bool discovery;
}

/// The one request sent to the hardware after merging every demand.
@immutable
class HardwareRequest {
  /// Creates a request.
  const HardwareRequest({
    required this.location,
    required this.accelerometerPeriod,
    required this.barometer,
    required this.motion,
    required this.discovery,
  });

  /// GPS request, or null for no GPS.
  final LocationRequest? location;

  /// Accelerometer period, or null for none.
  final Duration? accelerometerPeriod;

  /// Barometer on.
  final bool barometer;

  /// Motion trigger on.
  final bool motion;

  /// Discovery on.
  final bool discovery;

  @override
  bool operator ==(Object other) =>
      other is HardwareRequest &&
      other.location?.interval == location?.interval &&
      other.location?.maxBatchDelay == location?.maxBatchDelay &&
      (other.location == null) == (location == null) &&
      other.accelerometerPeriod == accelerometerPeriod &&
      other.barometer == barometer &&
      other.motion == motion &&
      other.discovery == discovery;

  @override
  int get hashCode => Object.hash(
    location?.interval,
    location?.maxBatchDelay,
    accelerometerPeriod,
    barometer,
    motion,
    discovery,
  );
}

/// Merges engine demands into one hardware request: the fastest interval
/// wins; batching only if every GPS demand allows it.
abstract final class ResourceArbiter {
  /// Merges [demands].
  static HardwareRequest merge(List<Demand> demands) {
    final gps = demands.where((d) => d.gpsInterval != null).toList();
    LocationRequest? location;
    if (gps.isNotEmpty) {
      final interval = gps
          .map((d) => d.gpsInterval!)
          .reduce((a, b) => a < b ? a : b);
      final batching = gps.every((d) => d.allowBatching);
      final delay = batching
          ? Duration(
              microseconds: gps
                  .map((d) => d.maxBatchDelay.inMicroseconds)
                  .reduce(math.min),
            )
          : Duration.zero;
      location = LocationRequest(interval: interval, maxBatchDelay: delay);
    }
    final accel = demands
        .map((d) => d.accelerometerPeriod)
        .whereType<Duration>()
        .fold<Duration?>(null, (a, b) => a == null || b < a ? b : a);
    return HardwareRequest(
      location: location,
      accelerometerPeriod: accel,
      barometer: demands.any((d) => d.barometer),
      motion: demands.any((d) => d.motion),
      discovery: demands.any((d) => d.discovery),
    );
  }
}
