import 'package:test/test.dart';

import '../tool/src/route_tools.dart';

void main() {
  group('chainWays', () {
    const a = [(30.0, 79.0), (30.1, 79.0)];
    const b = [(30.1, 79.0), (30.2, 79.0)];
    const c = [(30.2, 79.0), (30.3, 79.0)];

    test('joins ways that already run end to start', () {
      expect(chainWays([a, b, c]), [
        (30.0, 79.0),
        (30.1, 79.0),
        (30.2, 79.0),
        (30.3, 79.0),
      ]);
    });

    test('reverses a way that runs the other direction', () {
      final b2 = b.reversed.toList();
      expect(chainWays([a, b2, c]).map((p) => p.$1), [
        30.0,
        30.1,
        30.2,
        30.3,
      ]);
    });

    test('works from the other end when the first way is listed last', () {
      expect(chainWays([c, b, a]).first.$1, anyOf(30.0, 30.3));
      expect(chainWays([c, b, a]), hasLength(4));
    });

    test('a gap between ways is refused, never bridged silently', () {
      const far = [(31.0, 79.0), (31.1, 79.0)];
      expect(() => chainWays([a, far]), throwsA(isA<RouteGapError>()));
    });

    test('a single way is returned as is', () {
      expect(chainWays([a]), a);
    });

    test('no ways is an error', () {
      expect(() => chainWays([]), throwsArgumentError);
    });
  });

  group('gpx writer', () {
    test('writes track points with elevation and named waypoints', () {
      final xml = writeGpx(
        name: 'Lohajung-Brahmatal',
        attribution: 'OpenStreetMap contributors (ODbL)',
        points: const [(30.1, 79.6, 2373.0), (30.2, 79.5, 3216.0)],
        waypoints: const [('Start', 30.1, 79.6), ('Lake & Top', 30.2, 79.5)],
      );
      expect(xml, contains('<trkpt lat="30.1" lon="79.6"><ele>2373.0</ele>'));
      expect(xml, contains('<wpt lat="30.2" lon="79.5"><name>Lake &amp; Top'));
      expect(xml, contains('OpenStreetMap contributors'));
      expect(xml, startsWith('<?xml'));
    });

    test('points without elevation are written without an ele tag', () {
      final xml = writeGpx(
        name: 'x',
        attribution: 'y',
        points: const [(30.1, 79.6, null)],
        waypoints: const [],
      );
      expect(xml, contains('<trkpt lat="30.1" lon="79.6"></trkpt>'));
    });
  });

  group('elevation smoothing', () {
    test('a single spike from the elevation model is flattened', () {
      final out = smoothElevation([100, 102, 500, 104, 106]);
      expect(out[2], lessThan(200));
    });

    test('a steady climb is kept', () {
      final out = smoothElevation([0, 10, 20, 30, 40, 50]);
      expect(out.first, closeTo(0, 6));
      expect(out.last, closeTo(50, 6));
      expect(out[3] > out[2], isTrue);
    });

    test('short lists are returned unchanged', () {
      expect(smoothElevation([1, 2]), [1, 2]);
    });
  });
}
