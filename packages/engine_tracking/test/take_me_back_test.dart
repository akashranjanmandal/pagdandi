import 'package:core_geo/core_geo.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:test/test.dart';

const start = GeoPoint(27, 88);

/// A breadcrumb walking east, one point every 10 m.
List<GeoPoint> east(int n) => [
  for (var i = 0; i < n; i++)
    destination(start, bearing: 90, distanceM: i * 10),
];

void main() {
  test('no breadcrumb means no guidance', () {
    expect(takeMeBack(const [], start), isNull);
  });

  test('points back along the trail toward the start', () {
    final crumbs = east(21); // 200 m east
    final here = crumbs.last;
    final g = takeMeBack(crumbs, here)!;
    expect(g.bearingDeg, closeTo(270, 1));
    expect(g.remainingM, closeTo(200, 1));
    expect(g.arrived, isFalse);
  });

  test(
    'aims at a point about 30 m back (the lookahead), not the next vertex',
    () {
      final crumbs = east(21);
      final g = takeMeBack(crumbs, crumbs.last)!;
      expect(g.distanceToNextM, closeTo(30, 1));
    },
  );

  test('near the start the target is the start itself', () {
    final crumbs = east(21);
    final here = crumbs[2]; // 20 m from start
    final g = takeMeBack(crumbs, here)!;
    expect(g.next, crumbs.first);
    expect(g.distanceToNextM, closeTo(20, 1));
    expect(g.remainingM, closeTo(20, 1));
  });

  test('has arrived when within the arrive radius of the start', () {
    final crumbs = east(21);
    final g = takeMeBack(
      crumbs,
      destination(start, bearing: 90, distanceM: 10),
    )!;
    expect(g.arrived, isTrue);
  });

  test('when off the trail, remaining includes the way back onto it', () {
    final crumbs = east(21);
    final off = destination(crumbs[10], bearing: 0, distanceM: 40);
    final g = takeMeBack(crumbs, off)!;
    // 40 m back to the trail, then 100 m to the start
    expect(g.remainingM, closeTo(140, 3));
  });

  test('a single-point breadcrumb guides straight to that point', () {
    final here = destination(start, bearing: 0, distanceM: 500);
    final g = takeMeBack([start], here)!;
    expect(g.bearingDeg, closeTo(180, 0.5));
    expect(g.remainingM, closeTo(500, 1));
  });

  test('a looping trail uses the vertex nearest to where you are', () {
    final loop = [
      ...east(11),
      for (var i = 1; i <= 10; i++)
        destination(
          destination(start, bearing: 90, distanceM: 100),
          bearing: 0,
          distanceM: i * 10,
        ),
    ];
    final g = takeMeBack(loop, loop.last)!;
    expect(g.remainingM, closeTo(200, 2));
  });
}
