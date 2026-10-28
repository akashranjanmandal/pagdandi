import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/route_scene.dart';

/// A route going north 1 km, with an elevation climb from 2000 to 2100.
Route northRoute({bool ele = true}) => Route(
  id: 'n',
  name: 'N',
  points: [
    for (var i = 0; i <= 10; i++)
      RoutePoint(30 + i * 0.0009, 79, ele: ele ? 2000.0 + i * 10 : null),
  ],
  waypoints: const [Waypoint('Mid', 30.0045, 79), Waypoint('End', 30.009, 79)],
  attribution: 'a',
);

void main() {
  test('north is up: the start is below the end', () {
    final s = RouteScene.of(northRoute(), aspect: 1, progressM: 0);
    expect(s.line.first.dy, greaterThan(s.line.last.dy));
    expect(s.line.first.dx, closeTo(s.line.last.dx, 0.001));
  });

  test('everything is inside the unit square with a margin', () {
    final s = RouteScene.of(northRoute(), aspect: 1, progressM: 0);
    for (final p in s.line) {
      expect(p.dx, inInclusiveRange(0.035, 0.965));
      expect(p.dy, inInclusiveRange(0.035, 0.965));
    }
  });

  test('the shape is not stretched: a wide box leaves room at the sides', () {
    final wide = RouteScene.of(northRoute(), aspect: 2, progressM: 0);
    // A north-south line fills the height and is centred horizontally.
    expect(
      wide.line.first.dx,
      closeTo(1.0, 0.001),
      reason: 'centre of a 2:1 box',
    );
    expect(wide.line.first.dy, closeTo(0.96, 0.01));
    expect(wide.line.last.dy, closeTo(0.04, 0.01));
  });

  test('an east-west trail keeps its proportions', () {
    final r = Route(
      id: 'e',
      name: 'E',
      points: [for (var i = 0; i <= 10; i++) RoutePoint(30, 79 + i * 0.001)],
      attribution: 'a',
    );
    final s = RouteScene.of(r, aspect: 1, progressM: 0);
    expect(s.line.first.dx, lessThan(s.line.last.dx));
    expect(s.line.first.dy, closeTo(s.line.last.dy, 0.001));
  });

  test('checkpoints are placed on the line and marked passed or not', () {
    final s = RouteScene.of(northRoute(), aspect: 1, progressM: 600);
    expect(s.checkpoints.map((c) => c.name), ['Mid', 'End']);
    expect(s.checkpoints.first.passed, isTrue);
    expect(s.checkpoints.last.passed, isFalse);
  });

  test('the walker marker is where the walker is, not snapped', () {
    final s = RouteScene.of(
      northRoute(),
      aspect: 1,
      progressM: 500,
      me: const GeoPoint(30.0045, 79.002),
    );
    expect(s.me, isNotNull);
    expect(s.me!.dx, greaterThan(s.line[5].dx), reason: 'east of the trail');
  });

  test('a walker far from the route still fits in the picture', () {
    final s = RouteScene.of(
      northRoute(),
      aspect: 1,
      progressM: 500,
      me: const GeoPoint(30.0045, 79.02),
    );
    expect(s.me!.dx, inInclusiveRange(0.0, 1.0));
    expect(s.me!.dy, inInclusiveRange(0.0, 1.0));
  });

  test('no position yet means no marker', () {
    expect(RouteScene.of(northRoute(), aspect: 1, progressM: 0).me, isNull);
  });

  test('the done part of the line ends where the walker is', () {
    final s = RouteScene.of(northRoute(), aspect: 1, progressM: 500);
    expect(s.doneUntil, inInclusiveRange(4, 6));
    expect(RouteScene.of(northRoute(), aspect: 1, progressM: 0).doneUntil, 0);
    expect(
      RouteScene.of(northRoute(), aspect: 1, progressM: 99999).doneUntil,
      s.line.length - 1,
    );
  });

  group('elevation profile', () {
    test('runs left to right with high ground at the top', () {
      final s = RouteScene.of(northRoute(), aspect: 1, progressM: 0);
      expect(s.profile.first.dx, 0);
      expect(s.profile.last.dx, closeTo(1, 1e-9));
      expect(
        s.profile.first.dy,
        closeTo(1, 1e-9),
        reason: 'lowest at the bottom',
      );
      expect(s.profile.last.dy, closeTo(0, 1e-9));
      expect(s.minEle, 2000);
      expect(s.maxEle, 2100);
      expect(s.startEle, 2000);
      expect(s.endEle, 2100);
    });

    test('shows where the walker is along it', () {
      final s = RouteScene.of(northRoute(), aspect: 1, progressM: 500);
      expect(s.profileMe!.dx, closeTo(0.5, 0.02));
      expect(s.profileMe!.dy, closeTo(0.5, 0.05));
    });

    test('a route without elevation has no profile, no claim', () {
      final s = RouteScene.of(northRoute(ele: false), aspect: 1, progressM: 0);
      expect(s.profile, isEmpty);
      expect(s.profileMe, isNull);
      expect(s.hasProfile, isFalse);
    });

    test('a flat route does not divide by zero', () {
      final r = Route(
        id: 'f',
        name: 'F',
        points: [
          for (var i = 0; i <= 5; i++)
            RoutePoint(30 + i * 0.001, 79, ele: 2500),
        ],
        attribution: 'a',
      );
      final s = RouteScene.of(r, aspect: 1, progressM: 0);
      expect(s.profile.every((p) => p.dy.isFinite), isTrue);
    });
  });

  test('a long route is thinned to a drawable number of points', () {
    final r = Route(
      id: 'l',
      name: 'L',
      points: [
        for (var i = 0; i <= 5000; i++)
          RoutePoint(30 + i * 0.00001, 79, ele: 2000),
      ],
      attribution: 'a',
    );
    final s = RouteScene.of(r, aspect: 1, progressM: 0);
    expect(s.line.length, lessThanOrEqualTo(600));
    expect(s.line.first, isA<Offset>());
  });
}
