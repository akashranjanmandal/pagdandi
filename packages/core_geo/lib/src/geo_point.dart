import 'package:meta/meta.dart';

/// A position on Earth in degrees.
@immutable
class GeoPoint {
  /// Creates a point.
  const GeoPoint(this.lat, this.lon)
    : assert(lat >= -90 && lat <= 90, 'latitude out of range'),
      assert(lon >= -180 && lon <= 180, 'longitude out of range');

  /// Degrees north.
  final double lat;

  /// Degrees east.
  final double lon;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() => 'GeoPoint($lat, $lon)';
}
