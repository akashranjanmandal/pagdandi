import 'dart:math' as math;
import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:path_drawing/path_drawing.dart';

/// A friend marker on the map.
@immutable
class MapFriend {
  /// Creates a friend marker.
  const MapFriend(this.pos, this.initials, {required this.outOfRange});

  /// World position.
  final Offset pos;

  /// Two letters shown in the ring.
  final String initials;

  /// Dashed hollow ring when out of range.
  final bool outOfRange;
}

/// Where everything is on the sample trek map for one [NavState]. Pure
/// geometry: the painter only draws it. Sample data until real routes arrive.
class MapScene {
  MapScene._({
    required this.route,
    required this.branch,
    required this.junction,
    required this.junctionAlongRoute,
    required this.you,
    required this.youAlongRoute,
    required this.headingDeg,
    required this.friends,
    required this.breadcrumb,
    required this.showJunctionHighlight,
    required this.takenBranch,
    required this.hollowYou,
    required this.pulse,
  });

  /// Builds the scene for [nav].
  factory MapScene.of(NavState nav) {
    final route = parseSvgPathData(_route);
    final rm = route.computeMetrics().first;
    final len = rm.length;
    final lj = len * .52;
    final jt = rm.getTangentForOffset(lj)!;
    final j = jt.position;

    // The other branch leaves the fork 0.9 rad to the right of the route.
    final ba = jt.angle * -1 + 0.9; // Tangent.angle is counter-clockwise
    final dir = Offset(math.cos(ba), math.sin(ba));
    final perp = Offset(-dir.dy, dir.dx);
    final branch = Path()
      ..moveTo(j.dx, j.dy)
      ..cubicTo(
        j.dx + dir.dx * 50,
        j.dy + dir.dy * 50,
        j.dx + dir.dx * 110 + perp.dx * 14,
        j.dy + dir.dy * 110 + perp.dy * 14,
        j.dx + dir.dx * 190,
        j.dy + dir.dy * 190,
      );
    final bm = branch.computeMetrics().first;

    Offset at(double l) => rm.getTangentForOffset(l.clamp(0, len))!.position;
    double angleAt(double l) =>
        -rm.getTangentForOffset(l.clamp(0, len))!.angle; // clockwise, screen
    double bearing(double rad) => rad * 180 / math.pi + 90;

    var youL = len * .30;
    var ref = youL;
    if (nav == NavState.junction) {
      youL = lj - 27;
      ref = youL;
    }
    var you = at(youL);
    var heading = bearing(angleAt(youL));
    final onBranch = nav == NavState.offRoute;
    if (onBranch) {
      you = bm.getTangentForOffset(46)!.position;
      heading = bearing(math.atan2(j.dy - you.dy, j.dx - you.dx));
      ref = lj - 27;
    }
    if (nav == NavState.wrongWay) heading += 180;

    Offset beside(double l) {
      final a = angleAt(l.clamp(10, len - 10));
      final p = at(l.clamp(10, len - 10));
      return p + Offset(math.cos(a + 1.57), math.sin(a + 1.57)) * 9;
    }

    final friends = nav == NavState.regroup
        ? [
            MapFriend(beside(len * .30 - 70), 'RK', outOfRange: true),
            MapFriend(beside(ref + 70), 'AS', outOfRange: false),
            MapFriend(beside(ref + 130), 'MD', outOfRange: false),
          ]
        : [
            MapFriend(beside(ref - 20), 'RK', outOfRange: false),
            MapFriend(beside(ref + 70), 'AS', outOfRange: false),
            MapFriend(beside(ref + 130), 'MD', outOfRange: false),
          ];

    List<Offset> sample(PathMetric m, double from, double to) => [
      for (var l = from; l <= to; l += 5) m.getTangentForOffset(l)!.position,
    ];
    final crumb = onBranch
        ? [...sample(rm, 0, lj), ...sample(bm, 0, 46)]
        : sample(rm, 0, youL);
    crumb.add(you);

    return MapScene._(
      route: route,
      branch: branch,
      junction: j,
      junctionAlongRoute: lj,
      you: you,
      youAlongRoute: onBranch ? lj : youL,
      headingDeg: heading % 360,
      friends: friends,
      breadcrumb: crumb,
      showJunctionHighlight: nav == NavState.junction,
      takenBranch: onBranch,
      hollowYou: nav == NavState.gpsLost,
      pulse: nav == NavState.regroup,
    );
  }

  /// The planned route.
  final Path route;

  /// The branch you did not choose (or took, see [takenBranch]).
  final Path branch;

  /// The fork.
  final Offset junction;

  /// Distance along the route of the fork.
  final double junctionAlongRoute;

  /// Your position.
  final Offset you;

  /// Distance along the route nearest to you.
  final double youAlongRoute;

  /// Facing, degrees from north (0 = up).
  final double headingDeg;

  /// Friend markers.
  final List<MapFriend> friends;

  /// Dots where you have been, ending at you.
  final List<Offset> breadcrumb;

  /// Whether the fork node is highlighted (junction ahead).
  final bool showJunctionHighlight;

  /// Whether you are on the unchosen branch (drawn in warn).
  final bool takenBranch;

  /// Hollow position (GPS lost).
  final bool hollowYou;

  /// Whether your marker pulses (beacon live while regrouping).
  final bool pulse;

  static const String _route =
      'M40 470 C100 450 150 430 200 400 S 270 340 310 300 S 370 230 420 190 '
      'S 500 120 560 80';

  /// Shortest distance from [p] to the route.
  double distanceToRoute(Offset p) {
    final m = route.computeMetrics().first;
    var best = double.infinity;
    for (var l = 0.0; l <= m.length; l += 1) {
      best = math.min(best, (m.getTangentForOffset(l)!.position - p).distance);
    }
    return best;
  }
}
