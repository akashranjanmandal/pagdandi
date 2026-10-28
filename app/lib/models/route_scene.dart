import 'dart:math' as math;
import 'dart:ui';

import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:meta/meta.dart';

/// A named place on the picture.
@immutable
class ScenePlace {
  /// Creates a place.
  const ScenePlace(this.name, this.at, {required this.passed});

  /// Its name.
  final String name;

  /// Where, in the unit box.
  final Offset at;

  /// The walker is already past it.
  final bool passed;
}

/// Everything the route panel draws, as numbers in a unit box (x right,
/// y down, north up). Pure geometry: the painter only draws it.
class RouteScene {
  RouteScene._({
    required this.line,
    required this.doneUntil,
    required this.checkpoints,
    required this.me,
    required this.profile,
    required this.profileMe,
    required this.minEle,
    required this.maxEle,
    required this.startEle,
    required this.endEle,
  });

  /// Builds the picture for a box of width / height = [aspect]. The shape is
  /// never stretched: the longer side of the trail fills the box.
  factory RouteScene.of(
    Route route, {
    required double aspect,
    required double progressM,
    GeoPoint? me,
  }) {
    // Thin very long routes so painting stays cheap.
    final step = math.max(1, (route.geo.length / 500).ceil());
    final idx = <int>[
      for (var i = 0; i < route.geo.length; i += step) i,
      if ((route.geo.length - 1) % step != 0) route.geo.length - 1,
    ];
    final pts = [for (final i in idx) route.geo[i]];

    final lat0 = pts.first.lat;
    final cosLat = math.cos(lat0 * math.pi / 180);
    double xm(GeoPoint p) => p.lon * cosLat * 111195;
    double ym(GeoPoint p) => p.lat * 111195;
    final all = [...pts, ?me];
    final minX = all.map(xm).reduce(math.min);
    final maxX = all.map(xm).reduce(math.max);
    final minY = all.map(ym).reduce(math.min);
    final maxY = all.map(ym).reduce(math.max);
    final w = math.max(maxX - minX, 1);
    final h = math.max(maxY - minY, 1);
    const margin = 0.04;
    final boxW = aspect;
    const boxH = 1.0;
    final scale = math.min(
      (boxW - 2 * margin * boxW) / w,
      (boxH - 2 * margin * boxH) / h,
    );
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    // Unit box in x is 0..aspect; normalise to 0..aspect so a wide box keeps
    // its width (the painter multiplies by height).
    Offset at(GeoPoint p) => Offset(
      boxW / 2 + (xm(p) - cx) * scale,
      boxH / 2 - (ym(p) - cy) * scale,
    );

    final line = [for (final p in pts) at(p)];
    var done = 0;
    for (var k = 0; k < idx.length; k++) {
      if (route.cumulativeM[idx[k]] <= progressM) done = k;
    }
    if (progressM >= route.totalM) done = line.length - 1;

    final places = [
      for (final c in route.checkpoints)
        ScenePlace(c.name, at(c.point), passed: progressM >= c.distanceAlongM),
    ];

    final hasEle = route.hasElevation;
    final eles = hasEle ? [for (final p in route.points) p.ele!] : <double>[];
    final minE = hasEle ? eles.reduce(math.min) : 0.0;
    final maxE = hasEle ? eles.reduce(math.max) : 0.0;
    final span = maxE - minE;
    Offset prof(double dist, double e) => Offset(
      route.totalM == 0 ? 0 : dist / route.totalM,
      span == 0 ? 0.5 : 1 - (e - minE) / span,
    );
    final profile = hasEle
        ? [
            for (final i in idx)
              prof(route.cumulativeM[i], route.points[i].ele!),
          ]
        : <Offset>[];
    Offset? profMe;
    if (hasEle) {
      var j = 0;
      for (var i = 0; i < route.cumulativeM.length - 1; i++) {
        if (route.cumulativeM[i] <= progressM) j = i;
      }
      final span2 = route.cumulativeM[j + 1] - route.cumulativeM[j];
      final t = span2 == 0
          ? 0.0
          : ((progressM - route.cumulativeM[j]) / span2).clamp(0.0, 1.0);
      final e =
          route.points[j].ele! +
          (route.points[j + 1].ele! - route.points[j].ele!) * t;
      profMe = prof(math.min(progressM, route.totalM), e);
    }

    return RouteScene._(
      line: line,
      doneUntil: done,
      checkpoints: places,
      me: me == null ? null : at(me),
      profile: profile,
      profileMe: profMe,
      minEle: minE,
      maxEle: maxE,
      startEle: hasEle ? route.points.first.ele! : 0,
      endEle: hasEle ? route.points.last.ele! : 0,
    );
  }

  /// The trail, thinned, in the box (width = aspect, height = 1).
  final List<Offset> line;

  /// Index into [line] up to which the walker has been.
  final int doneUntil;

  /// Named places on the trail.
  final List<ScenePlace> checkpoints;

  /// The walker, if a position is known.
  final Offset? me;

  /// Elevation along the trail: x 0..1 of the distance, y 0 high .. 1 low.
  final List<Offset> profile;

  /// The walker on the profile.
  final Offset? profileMe;

  /// Lowest elevation, metres.
  final double minEle;

  /// Highest elevation, metres.
  final double maxEle;

  /// Elevation at the start, metres.
  final double startEle;

  /// Elevation at the end, metres.
  final double endEle;

  /// Whether the route has elevation to draw.
  bool get hasProfile => profile.isNotEmpty;
}
