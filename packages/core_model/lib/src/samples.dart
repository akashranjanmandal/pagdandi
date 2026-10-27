import 'package:meta/meta.dart';

/// One accelerometer reading in m/s^2.
@immutable
class AccelSample {
  /// Creates a sample.
  const AccelSample({
    required this.x,
    required this.y,
    required this.z,
    required this.at,
  });

  /// X axis.
  final double x;

  /// Y axis.
  final double y;

  /// Z axis.
  final double z;

  /// Monotonic time of the reading.
  final Duration at;
}

/// One barometer reading.
@immutable
class PressureSample {
  /// Creates a sample.
  const PressureSample({required this.hPa, required this.at});

  /// Pressure in hectopascals.
  final double hPa;

  /// Monotonic time of the reading.
  final Duration at;
}
