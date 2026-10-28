import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 12, 14, 6);
const origin = GeoPoint(30, 79);

Route route({List<Waypoint> waypoints = const []}) {
  final pts = <RoutePoint>[];
  var p = origin;
  for (var i = 0; i <= 200; i++) {
    pts.add(RoutePoint(p.lat, p.lon));
    p = destination(p, bearing: 0, distanceM: 10);
  }
  return Route(
    id: 'r',
    name: 'R',
    points: pts,
    waypoints: waypoints,
    attribution: 'a',
  );
}

/// A fix [along] metres up the route and [side] metres to the east.
NavFix fix(double along, {double side = 0, double acc = 8, int sec = 0}) {
  final p = destination(
    destination(origin, bearing: 0, distanceM: along),
    bearing: 90,
    distanceM: side,
  );
  return NavFix(
    position: p,
    accuracyM: acc,
    time: t0.add(Duration(seconds: sec)),
  );
}

void main() {
  late NavigationTracker t;
  setUp(() => t = NavigationTracker(route()));

  group('on route', () {
    test('reports progress and what is left', () {
      final s = t.onFix(fix(500))!;
      expect(s.status, NavStatus.onRoute);
      expect(s.progressM, closeTo(500, 3));
      expect(s.remainingM, closeTo(1500, 3));
      expect(s.totalM, closeTo(2000, 2));
    });

    test('bearing to go is the direction of the route ahead', () {
      expect(t.onFix(fix(500))!.bearingToGoDeg, closeTo(0, 2));
    });

    test('a little drift to the side is still on route', () {
      expect(t.onFix(fix(500, side: 15))!.status, NavStatus.onRoute);
    });

    test('nothing before the first fix', () {
      expect(t.current, isNull);
    });
  });

  group('off route', () {
    test('needs three fixes in a row beyond the limit', () {
      expect(t.onFix(fix(500, side: 60))!.status, NavStatus.onRoute);
      expect(t.onFix(fix(510, side: 60, sec: 5))!.status, NavStatus.onRoute);
      expect(t.onFix(fix(520, side: 60, sec: 10))!.status, NavStatus.offRoute);
    });

    test('one good fix in between starts the count again', () {
      t
        ..onFix(fix(500, side: 60))
        ..onFix(fix(505, side: 60, sec: 5))
        ..onFix(fix(510, side: 5, sec: 10));
      expect(t.onFix(fix(515, side: 60, sec: 15))!.status, NavStatus.onRoute);
    });

    test('a poor GPS accuracy widens the limit (2 x accuracy)', () {
      for (var i = 0; i < 4; i++) {
        final s = t.onFix(fix(500 + i * 5.0, side: 60, acc: 40, sec: i * 5))!;
        expect(s.status, NavStatus.onRoute, reason: '60 m is within 2 x 40 m');
      }
    });

    test('the limit is never below 25 m even with excellent accuracy', () {
      for (var i = 0; i < 4; i++) {
        final s = t.onFix(fix(500 + i * 5.0, side: 20, acc: 3, sec: i * 5))!;
        expect(s.status, NavStatus.onRoute);
      }
    });

    test('clears once back within 15 m of the route', () {
      for (var i = 0; i < 3; i++) {
        t.onFix(fix(500 + i * 5.0, side: 80, sec: i * 5));
      }
      expect(t.current!.status, NavStatus.offRoute);
      expect(
        t.onFix(fix(520, side: 20, sec: 20))!.status,
        NavStatus.offRoute,
        reason: '20 m is not yet back (clears below 15 m)',
      );
      expect(t.onFix(fix(520, side: 10, sec: 25))!.status, NavStatus.onRoute);
    });

    test('when off route the bearing points back at the route', () {
      for (var i = 0; i < 3; i++) {
        t.onFix(fix(500, side: 80, sec: i * 5));
      }
      // The route is to the west of an eastern fix.
      expect(t.current!.bearingToGoDeg, closeTo(270, 5));
      expect(t.current!.crossTrackM, closeTo(80, 2));
    });
  });

  group('wrong way', () {
    test('steadily going back toward the start is a wrong way', () {
      var s = t.onFix(fix(800))!;
      for (var i = 1; i <= 6; i++) {
        s = t.onFix(fix(800 - i * 15.0, sec: i * 10))!;
      }
      expect(s.status, NavStatus.wrongWay);
    });

    test('standing still is not a wrong way', () {
      NavSnapshot? s;
      for (var i = 0; i < 8; i++) {
        s = t.onFix(fix(800 + (i.isEven ? 2 : -2), sec: i * 10));
      }
      expect(s!.status, NavStatus.onRoute);
    });

    test('GPS jitter going back a few metres is not a wrong way', () {
      var s = t.onFix(fix(800))!;
      for (var i = 1; i <= 6; i++) {
        s = t.onFix(fix(800 - i * 2.0, sec: i * 10))!;
      }
      expect(s.status, NavStatus.onRoute);
    });

    test('clears when moving forward again', () {
      var s = t.onFix(fix(800))!;
      for (var i = 1; i <= 6; i++) {
        s = t.onFix(fix(800 - i * 15.0, sec: i * 10))!;
      }
      expect(s.status, NavStatus.wrongWay);
      for (var i = 1; i <= 3; i++) {
        s = t.onFix(fix(710 + i * 15.0, sec: 70 + i * 10))!;
      }
      expect(s.status, NavStatus.onRoute);
    });

    test('reversing the route makes the return trip correct', () {
      t.reverse();
      var s = t.onFix(fix(1400))!;
      for (var i = 1; i <= 6; i++) {
        s = t.onFix(fix(1400 - i * 15.0, sec: i * 10))!;
      }
      expect(s.status, NavStatus.onRoute);
      expect(t.isReversed, isTrue);
    });
  });

  group('GPS lost', () {
    test('silence beyond the limit is GPS lost, not off route', () {
      t.onFix(fix(500));
      final s = t.onTick(t0.add(const Duration(seconds: 90)))!;
      expect(s.status, NavStatus.gpsLost);
      expect(s.progressM, closeTo(500, 3), reason: 'keeps the last progress');
    });

    test('a short silence is nothing', () {
      t.onFix(fix(500));
      expect(t.onTick(t0.add(const Duration(seconds: 30))), isNull);
      expect(t.current!.status, NavStatus.onRoute);
    });

    test('the next fix ends it without a false off-route', () {
      t.onFix(fix(500));
      t.onTick(t0.add(const Duration(seconds: 90)));
      final s = t.onFix(fix(560, sec: 95))!;
      expect(s.status, NavStatus.onRoute);
    });

    test('a tick before any fix does nothing', () {
      expect(t.onTick(t0), isNull);
    });
  });

  group('arrival and checkpoints', () {
    test('within 30 m of the end counts as arrived', () {
      expect(t.onFix(fix(1985))!.arrived, isTrue);
      expect(t.onFix(fix(1500))!.arrived, isFalse);
    });

    test('the next checkpoint and its distance are given', () {
      final tr = NavigationTracker(
        route(
          waypoints: [
            Waypoint(
              'Lake',
              destination(origin, bearing: 0, distanceM: 1000).lat,
              79,
            ),
          ],
        ),
      );
      final s = tr.onFix(fix(400))!;
      expect(s.nextCheckpoint!.name, 'Lake');
      expect(s.distanceToCheckpointM, closeTo(600, 5));
    });

    test('a checkpoint already passed is not next', () {
      final tr = NavigationTracker(
        route(
          waypoints: [
            Waypoint(
              'Lake',
              destination(origin, bearing: 0, distanceM: 1000).lat,
              79,
            ),
          ],
        ),
      );
      expect(tr.onFix(fix(1200))!.nextCheckpoint, isNull);
    });
  });

  group('crossing a checkpoint', () {
    test('is announced once when passed', () {
      final tr = NavigationTracker(
        route(
          waypoints: [
            Waypoint(
              'Lake',
              destination(origin, bearing: 0, distanceM: 1000).lat,
              79,
            ),
          ],
        ),
      );
      final names = <String>[];
      for (var i = 0; i < 6; i++) {
        final s = tr.onFix(fix(960 + i * 20.0, sec: i * 10))!;
        if (s.reachedCheckpoint != null) names.add(s.reachedCheckpoint!.name);
      }
      expect(names, ['Lake']);
    });
  });
}
