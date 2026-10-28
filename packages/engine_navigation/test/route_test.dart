import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:test/test.dart';

/// A straight route going north along one meridian, a point every ~[stepM].
Route northRoute({
  int points = 101,
  double stepM = 10,
  List<Waypoint> waypoints = const [],
}) {
  final pts = <RoutePoint>[];
  var p = const GeoPoint(30, 79);
  for (var i = 0; i < points; i++) {
    pts.add(RoutePoint(p.lat, p.lon, ele: 2000.0 + i));
    p = destination(p, bearing: 0, distanceM: stepM);
  }
  return Route(
    id: 'north',
    name: 'North',
    points: pts,
    waypoints: waypoints,
    attribution: 'test',
  );
}

void main() {
  group('Route', () {
    test('length is the sum of segment lengths', () {
      final r = northRoute();
      expect(r.totalM, closeTo(1000, 1));
      expect(r.cumulativeM.first, 0);
      expect(r.cumulativeM.last, closeTo(1000, 1));
    });

    test('climb and descent ignore small elevation noise', () {
      final pts = [
        const RoutePoint(30, 79, ele: 100),
        const RoutePoint(30.001, 79, ele: 101),
        const RoutePoint(30.002, 79, ele: 100),
        const RoutePoint(30.003, 79, ele: 140),
        const RoutePoint(30.004, 79, ele: 120),
      ];
      final r = Route(id: 'x', name: 'x', points: pts, attribution: 'a');
      expect(r.climbM, closeTo(40, 0.01));
      expect(r.descentM, closeTo(20, 0.01));
    });

    test('climb still to do falls as you progress', () {
      final r = northRoute();
      expect(r.climbRemainingM(0), closeTo(r.climbM, 0.01));
      expect(r.climbRemainingM(r.totalM), closeTo(0, 0.01));
      final half = r.climbRemainingM(r.totalM / 2);
      expect(half, closeTo(r.climbM / 2, 4));
    });

    test('a route with no elevation has no climb figure', () {
      final r = Route(
        id: 'x',
        name: 'x',
        points: const [RoutePoint(30, 79), RoutePoint(30.01, 79)],
        attribution: 'a',
      );
      expect(r.hasElevation, isFalse);
      expect(r.climbM, 0);
    });

    test('needs at least two points', () {
      expect(
        () => Route(
          id: 'x',
          name: 'x',
          points: const [RoutePoint(30, 79)],
          attribution: 'a',
        ),
        throwsArgumentError,
      );
    });

    test('waypoints are snapped to the route and sorted by distance', () {
      final r = northRoute(
        waypoints: const [
          Waypoint('End', 30.0089, 79),
          Waypoint('Middle', 30.0045, 79.0001),
        ],
      );
      expect(r.checkpoints.map((c) => c.name), ['Middle', 'End']);
      expect(r.checkpoints.first.distanceAlongM, closeTo(500, 15));
    });

    test('a waypoint far from the route is not a checkpoint', () {
      final r = northRoute(waypoints: const [Waypoint('Far', 30.005, 79.05)]);
      expect(r.checkpoints, isEmpty);
    });

    test('reversed runs the other way with checkpoints re-measured', () {
      final r = northRoute(
        waypoints: const [Waypoint('Near start', 30.0009, 79)],
      );
      final back = r.reversed();
      expect(back.points.first.lat, r.points.last.lat);
      expect(back.totalM, closeTo(r.totalM, 0.01));
      expect(
        back.checkpoints.single.distanceAlongM,
        closeTo(r.totalM - 100, 15),
      );
      expect(back.id, '${r.id}-reversed');
    });

    test('project finds progress and cross-track on a straight route', () {
      final r = northRoute();
      final p = destination(
        const GeoPoint(30, 79),
        bearing: 0,
        distanceM: 400,
      );
      final side = destination(p, bearing: 90, distanceM: 30);
      final m = r.project(side);
      expect(m.progressM, closeTo(400, 2));
      expect(m.crossTrackM, closeTo(30, 1));
      expect(m.routeBearingDeg, closeTo(0, 1));
    });

    test('project beyond the end clamps to the end', () {
      final r = northRoute();
      final past = destination(
        const GeoPoint(30, 79),
        bearing: 0,
        distanceM: 1200,
      );
      final m = r.project(past);
      expect(m.progressM, closeTo(r.totalM, 0.5));
      expect(m.crossTrackM, closeTo(200, 3));
    });

    test('on an out-and-back path the hint picks the right pass', () {
      // Up 500 m then back down the same line.
      final up = [
        for (var i = 0; i <= 50; i++)
          destination(const GeoPoint(30, 79), bearing: 0, distanceM: i * 10.0),
      ];
      final pts = [
        for (final g in [...up, ...up.reversed.skip(1)])
          RoutePoint(g.lat, g.lon),
      ];
      final r = Route(id: 'ob', name: 'ob', points: pts, attribution: 'a');
      final spot = destination(
        const GeoPoint(30, 79),
        bearing: 0,
        distanceM: 300,
      );
      expect(r.project(spot, nearProgressM: 280).progressM, closeTo(300, 3));
      expect(r.project(spot, nearProgressM: 720).progressM, closeTo(700, 3));
    });

    test('positionAt returns the point at a distance along the route', () {
      final r = northRoute();
      final g = r.positionAt(250);
      expect(
        distanceM(
          g,
          destination(const GeoPoint(30, 79), bearing: 0, distanceM: 250),
        ),
        lessThan(1),
      );
      expect(r.positionAt(-5).lat, r.points.first.lat);
      expect(r.positionAt(99999).lat, r.points.last.lat);
    });
  });
}
