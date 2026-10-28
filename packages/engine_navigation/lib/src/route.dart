import 'dart:math' as math;

import 'package:core_geo/core_geo.dart';
import 'package:meta/meta.dart';

/// One point of a route, with an optional elevation in metres.
@immutable
class RoutePoint {
  /// Creates a point.
  const RoutePoint(this.lat, this.lon, {this.ele});

  /// Degrees north.
  final double lat;

  /// Degrees east.
  final double lon;

  /// Metres above sea level, if the file had it.
  final double? ele;

  /// As a [GeoPoint].
  GeoPoint get geo => GeoPoint(lat, lon);
}

/// A named place (lake, camp, pass) from the route file.
@immutable
class Waypoint {
  /// Creates a waypoint.
  const Waypoint(this.name, this.lat, this.lon);

  /// Its name.
  final String name;

  /// Degrees north.
  final double lat;

  /// Degrees east.
  final double lon;
}

/// A waypoint that lies on the route, with its distance from the start.
@immutable
class Checkpoint {
  /// Creates a checkpoint.
  const Checkpoint(this.name, this.distanceAlongM, this.point);

  /// Its name.
  final String name;

  /// Metres from the start of the route.
  final double distanceAlongM;

  /// Where it is.
  final GeoPoint point;
}

/// Where a position falls on a route.
@immutable
class RouteMatch {
  /// Creates a match.
  const RouteMatch({
    required this.progressM,
    required this.crossTrackM,
    required this.segment,
    required this.routeBearingDeg,
    required this.snapped,
  });

  /// Metres from the start, along the route.
  final double progressM;

  /// Metres from the route line (always positive).
  final double crossTrackM;

  /// Index of the segment (the one starting at that point).
  final int segment;

  /// Direction of the route at that place, degrees from north.
  final double routeBearingDeg;

  /// The closest point on the route.
  final GeoPoint snapped;
}

/// A trail to follow: points in order, named places on it, and its length.
class Route {
  /// Creates a route. Needs at least two points.
  Route({
    required this.id,
    required this.name,
    required this.points,
    required this.attribution,
    this.waypoints = const [],
  }) {
    if (points.length < 2) {
      throw ArgumentError('a route needs at least two points');
    }
    geo = [for (final p in points) p.geo];
    final cum = <double>[0];
    for (var i = 1; i < geo.length; i++) {
      cum.add(cum.last + distanceM(geo[i - 1], geo[i]));
    }
    cumulativeM = cum;
    _elevation();
    checkpoints = _snap();
  }

  /// Short stable id.
  final String id;

  /// Display name.
  final String name;

  /// The trail, in order.
  final List<RoutePoint> points;

  /// Named places from the file.
  final List<Waypoint> waypoints;

  /// Who made the data (shown to the user; OpenStreetMap needs this).
  final String attribution;

  /// [points] as geographic points.
  late final List<GeoPoint> geo;

  /// Metres from the start at each point.
  late final List<double> cumulativeM;

  /// Waypoints on the route, nearest the start first.
  late final List<Checkpoint> checkpoints;

  /// Total ascent in metres (changes under 3 m are ignored as noise).
  double climbM = 0;

  /// Total descent in metres.
  double descentM = 0;

  /// Whether every point has an elevation.
  bool hasElevation = false;

  /// Climb done at each point (same 3 m rule), for [climbRemainingM].
  List<double> _climbAt = const [];

  /// Length in metres.
  double get totalM => cumulativeM.last;

  /// Waypoints farther than this from the route are not checkpoints.
  static const double checkpointReachM = 300;

  void _elevation() {
    hasElevation = points.every((p) => p.ele != null);
    if (!hasElevation) return;
    var ref = points.first.ele!;
    final at = <double>[0];
    for (final p in points.skip(1)) {
      final d = p.ele! - ref;
      if (d >= 3) {
        climbM += d;
        ref = p.ele!;
      } else if (d <= -3) {
        descentM -= d;
        ref = p.ele!;
      }
      at.add(climbM);
    }
    _climbAt = at;
  }

  List<Checkpoint> _snap() {
    final out = <Checkpoint>[];
    for (final w in waypoints) {
      final m = project(GeoPoint(w.lat, w.lon));
      if (m.crossTrackM <= checkpointReachM) {
        out.add(Checkpoint(w.name, m.progressM, m.snapped));
      }
    }
    return out..sort((a, b) => a.distanceAlongM.compareTo(b.distanceAlongM));
  }

  /// The same trail walked the other way.
  Route reversed() => Route(
    id: id.endsWith('-reversed')
        ? id.substring(0, id.length - 9)
        : '$id-reversed',
    name: name,
    points: points.reversed.toList(),
    waypoints: waypoints,
    attribution: attribution,
  );

  static const double _mPerDegLat = 111195;

  /// Where [p] falls on the route. When the trail doubles back over itself,
  /// [nearProgressM] picks the pass closest to where the walker last was.
  RouteMatch project(GeoPoint p, {double? nearProgressM}) {
    final cosLat = math.cos(p.lat * math.pi / 180);
    double? bestCross;
    final cands = <(double, double, int, double, double)>[];
    for (var i = 0; i < geo.length - 1; i++) {
      final a = geo[i];
      final b = geo[i + 1];
      final ax = (a.lon - p.lon) * cosLat * _mPerDegLat;
      final ay = (a.lat - p.lat) * _mPerDegLat;
      final bx = (b.lon - p.lon) * cosLat * _mPerDegLat;
      final by = (b.lat - p.lat) * _mPerDegLat;
      final dx = bx - ax;
      final dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
      final cx = ax + t * dx;
      final cy = ay + t * dy;
      final cross = math.sqrt(cx * cx + cy * cy);
      final progress =
          cumulativeM[i] + t * (cumulativeM[i + 1] - cumulativeM[i]);
      cands.add((cross, progress, i, t, 0));
      if (bestCross == null || cross < bestCross) bestCross = cross;
    }
    final close = [
      for (final c in cands)
        if (c.$1 <= bestCross! + 8) c,
    ];
    var pick = close.first;
    if (nearProgressM != null) {
      for (final c in close) {
        if ((c.$2 - nearProgressM).abs() < (pick.$2 - nearProgressM).abs()) {
          pick = c;
        }
      }
    } else {
      for (final c in close) {
        if (c.$1 < pick.$1) pick = c;
      }
    }
    final i = pick.$3;
    final t = pick.$4;
    final a = geo[i];
    final b = geo[i + 1];
    final snapped = GeoPoint(
      a.lat + (b.lat - a.lat) * t,
      a.lon + (b.lon - a.lon) * t,
    );
    return RouteMatch(
      progressM: pick.$2,
      crossTrackM: pick.$1,
      segment: i,
      routeBearingDeg: bearingDeg(a, b),
      snapped: snapped,
    );
  }

  /// Climb still to do after [progressM] metres, 0 without elevation.
  double climbRemainingM(double progressM) {
    if (!hasElevation) return 0;
    var lo = 0;
    var hi = cumulativeM.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (cumulativeM[mid] <= progressM) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final i = progressM >= totalM ? hi : lo;
    return math.max(0, climbM - _climbAt[i]).toDouble();
  }

  /// The point [metres] from the start (clamped to the route).
  GeoPoint positionAt(double metres) {
    if (metres <= 0) return geo.first;
    if (metres >= totalM) return geo.last;
    var lo = 0;
    var hi = cumulativeM.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (cumulativeM[mid] <= metres) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = cumulativeM[hi] - cumulativeM[lo];
    final t = span == 0 ? 0.0 : (metres - cumulativeM[lo]) / span;
    final a = geo[lo];
    final b = geo[hi];
    return GeoPoint(a.lat + (b.lat - a.lat) * t, a.lon + (b.lon - a.lon) * t);
  }
}
