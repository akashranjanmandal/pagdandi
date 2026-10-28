import 'dart:math' as math;

import 'package:core_geo/src/geo_point.dart';
import 'package:meta/meta.dart';

/// Mean Earth radius in metres.
const double earthRadiusM = 6371008.8;

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

/// Great-circle distance in metres (haversine).
double distanceM(GeoPoint a, GeoPoint b) {
  final dLat = _rad(b.lat - a.lat);
  final dLon = _rad(b.lon - a.lon);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) *
          math.cos(_rad(b.lat)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}

/// Initial bearing from [a] to [b] in degrees from north, in [0, 360).
double bearingDeg(GeoPoint a, GeoPoint b) {
  final dLon = _rad(b.lon - a.lon);
  final y = math.sin(dLon) * math.cos(_rad(b.lat));
  final x =
      math.cos(_rad(a.lat)) * math.sin(_rad(b.lat)) -
      math.sin(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.cos(dLon);
  return (_deg(math.atan2(y, x)) + 360) % 360;
}

/// The point [distanceM] metres from [from] along [bearing] degrees.
GeoPoint destination(
  GeoPoint from, {
  required double bearing,
  required double distanceM,
}) {
  final d = distanceM / earthRadiusM;
  final b = _rad(bearing);
  final lat1 = _rad(from.lat);
  final lon1 = _rad(from.lon);
  final lat2 = math.asin(
    math.sin(lat1) * math.cos(d) + math.cos(lat1) * math.sin(d) * math.cos(b),
  );
  final lon2 =
      lon1 +
      math.atan2(
        math.sin(b) * math.sin(d) * math.cos(lat1),
        math.cos(d) - math.sin(lat1) * math.sin(lat2),
      );
  return GeoPoint(_deg(lat2), ((_deg(lon2) + 540) % 360) - 180);
}

/// Signed shortest turn from [from] to [to] degrees, in (-180, 180].
double angleDiffDeg(double from, double to) {
  final d = ((to - from) % 360 + 540) % 360 - 180;
  return d == -180 ? 180 : d;
}

/// Total length of a path in metres.
double pathLengthM(List<GeoPoint> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += distanceM(path[i - 1], path[i]);
  }
  return total;
}

/// The closest vertex of a path to a point.
@immutable
class NearestPoint {
  /// Creates a result.
  const NearestPoint(this.index, this.distanceM);

  /// Index into the path.
  final int index;

  /// Distance in metres.
  final double distanceM;
}

/// The vertex of [path] nearest to [p].
NearestPoint nearestOnPath(List<GeoPoint> path, GeoPoint p) {
  if (path.isEmpty) throw ArgumentError('path must not be empty');
  var best = 0;
  var bestD = distanceM(path[0], p);
  for (var i = 1; i < path.length; i++) {
    final d = distanceM(path[i], p);
    if (d < bestD) {
      best = i;
      bestD = d;
    }
  }
  return NearestPoint(best, bestD);
}
