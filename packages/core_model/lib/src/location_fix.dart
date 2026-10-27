import 'package:meta/meta.dart';

/// One position fix from the GPS receiver.
@immutable
class LocationFix {
  /// Creates a fix.
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.gpsTime,
    this.altitudeM,
    this.speedMps,
    this.bearingDeg,
  }) : assert(latitude >= -90 && latitude <= 90, 'latitude out of range'),
       assert(longitude >= -180 && longitude <= 180, 'longitude out of range'),
       assert(accuracyM >= 0, 'accuracy must not be negative');

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  /// Horizontal accuracy radius in metres.
  final double accuracyM;

  /// UTC time reported by GPS.
  final DateTime gpsTime;

  /// Altitude above sea level in metres, if known.
  final double? altitudeM;

  /// Ground speed in metres per second, if known.
  final double? speedMps;

  /// Direction of travel in degrees from north, if known.
  final double? bearingDeg;

  @override
  bool operator ==(Object other) =>
      other is LocationFix &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracyM == accuracyM &&
      other.gpsTime == gpsTime &&
      other.altitudeM == altitudeM &&
      other.speedMps == speedMps &&
      other.bearingDeg == bearingDeg;

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    accuracyM,
    gpsTime,
    altitudeM,
    speedMps,
    bearingDeg,
  );
}
