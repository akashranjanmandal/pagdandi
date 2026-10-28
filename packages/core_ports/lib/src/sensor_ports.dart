import 'package:core_model/core_model.dart';

/// What the engines ask of the location hardware. The ResourceArbiter merges
/// all engine demands into one of these.
class LocationRequest {
  /// Creates a request.
  const LocationRequest({
    required this.interval,
    this.maxBatchDelay = Duration.zero,
    this.minDistanceM = 0,
  });

  /// Desired time between fixes.
  final Duration interval;

  /// Longest the hardware may hold fixes back to save battery
  /// (zero = deliver live).
  final Duration maxBatchDelay;

  /// Minimum movement between fixes in metres.
  final double minDistanceM;
}

/// GPS position fixes.
abstract interface class LocationSource {
  /// Fixes as they arrive (batched fixes arrive in order).
  Stream<LocationFix> get fixes;

  /// Starts or changes the request; replaces any earlier one.
  Future<void> request(LocationRequest request);

  /// Stops delivering fixes.
  Future<void> stop();
}

/// Significant-motion trigger (hardware, near zero battery).
abstract interface class MotionSensor {
  /// Emits once each time significant motion is detected.
  Stream<void> get significantMotion;
}

/// Accelerometer (fall detection).
// A port is a deliberate one-method interface: fakes and adapters implement it.
// ignore: one_member_abstracts
abstract interface class Accelerometer {
  /// Samples at about [period] spacing while listened to.
  Stream<AccelSample> samples(Duration period);
}

/// Barometer (storm and ascent warnings).
abstract interface class Barometer {
  /// Pressure readings while listened to.
  Stream<PressureSample> get readings;
}
