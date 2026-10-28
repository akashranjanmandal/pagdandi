import 'dart:math';

import 'package:core_geo/core_geo.dart';
import 'package:test/test.dart';

void main() {
  // Darjeeling and Sandakphu: a known pair, about 53 km apart.
  const darjeeling = GeoPoint(27.0360, 88.2627);
  const sandakphu = GeoPoint(27.1020, 88.0010);

  group('distance', () {
    test('is zero between a point and itself', () {
      expect(distanceM(darjeeling, darjeeling), 0);
    });

    test('one degree of latitude is about 111.2 km', () {
      expect(
        distanceM(const GeoPoint(27, 88), const GeoPoint(28, 88)),
        closeTo(111195, 100),
      );
    });

    test(
      'agrees with an independent flat-earth estimate within 0.5 percent',
      () {
        const mPerDeg = 111195.0;
        final meanLat = (darjeeling.lat + sandakphu.lat) / 2 * pi / 180;
        final dy = (sandakphu.lat - darjeeling.lat) * mPerDeg;
        final dx = (sandakphu.lon - darjeeling.lon) * mPerDeg * cos(meanLat);
        final flat = sqrt(dx * dx + dy * dy);
        expect(distanceM(darjeeling, sandakphu), closeTo(flat, flat * 0.005));
      },
    );

    test('small distances are accurate (about 11 m for 0.0001 degrees)', () {
      expect(
        distanceM(const GeoPoint(27, 88), const GeoPoint(27.0001, 88)),
        closeTo(11.1, 0.1),
      );
    });

    test('a degree of longitude shrinks with latitude', () {
      final eq = distanceM(const GeoPoint(0, 88), const GeoPoint(0, 89));
      final hi = distanceM(const GeoPoint(60, 88), const GeoPoint(60, 89));
      expect(hi / eq, closeTo(0.5, 0.01));
    });

    test('properties: symmetric, non-negative, triangle inequality', () {
      final rnd = Random(7);
      GeoPoint any() =>
          GeoPoint(rnd.nextDouble() * 140 - 70, rnd.nextDouble() * 340 - 170);
      for (var i = 0; i < 300; i++) {
        final a = any();
        final b = any();
        final c = any();
        expect(distanceM(a, b), closeTo(distanceM(b, a), 1e-6));
        expect(distanceM(a, b), greaterThanOrEqualTo(0));
        expect(
          distanceM(a, c),
          lessThanOrEqualTo(distanceM(a, b) + distanceM(b, c) + 1e-6),
        );
      }
    });
  });

  group('bearing', () {
    test('north is 0, east 90, south 180, west 270', () {
      const o = GeoPoint(27, 88);
      expect(bearingDeg(o, const GeoPoint(27.1, 88)), closeTo(0, 0.01));
      expect(bearingDeg(o, const GeoPoint(27, 88.1)), closeTo(90, 0.1));
      expect(bearingDeg(o, const GeoPoint(26.9, 88)), closeTo(180, 0.01));
      expect(bearingDeg(o, const GeoPoint(27, 87.9)), closeTo(270, 0.1));
    });

    test('is always within [0, 360)', () {
      final rnd = Random(3);
      for (var i = 0; i < 300; i++) {
        final a = GeoPoint(
          rnd.nextDouble() * 100 - 50,
          rnd.nextDouble() * 300 - 150,
        );
        final b = GeoPoint(
          rnd.nextDouble() * 100 - 50,
          rnd.nextDouble() * 300 - 150,
        );
        final d = bearingDeg(a, b);
        expect(d, greaterThanOrEqualTo(0));
        expect(d, lessThan(360));
      }
    });

    test(
      'Darjeeling to Sandakphu points just north of west (about 286 degrees)',
      () {
        final b = bearingDeg(darjeeling, sandakphu);
        expect(b, inInclusiveRange(284, 288));
      },
    );
  });

  group('destination', () {
    test('moving a distance along a bearing lands that far away', () {
      final p = destination(darjeeling, bearing: 45, distanceM: 500);
      expect(distanceM(darjeeling, p), closeTo(500, 0.5));
      expect(bearingDeg(darjeeling, p), closeTo(45, 0.2));
    });

    test('round trip: out and back returns to the start', () {
      final out = destination(darjeeling, bearing: 120, distanceM: 2000);
      final back = destination(
        out,
        bearing: bearingDeg(out, darjeeling),
        distanceM: 2000,
      );
      expect(distanceM(back, darjeeling), lessThan(1));
    });
  });

  group('angles', () {
    test('angleDiffDeg is the signed shortest turn in (-180, 180]', () {
      expect(angleDiffDeg(350, 10), closeTo(20, 1e-9));
      expect(angleDiffDeg(10, 350), closeTo(-20, 1e-9));
      expect(angleDiffDeg(0, 180), closeTo(180, 1e-9));
      expect(angleDiffDeg(90, 90), 0);
    });
  });

  group('GeoPoint', () {
    test('compares by value', () {
      expect(const GeoPoint(1, 2), const GeoPoint(1, 2));
      expect(const GeoPoint(1, 2).hashCode, const GeoPoint(1, 2).hashCode);
      expect(const GeoPoint(1, 2), isNot(const GeoPoint(1, 3)));
    });

    test('rejects impossible coordinates', () {
      expect(() => GeoPoint(91, 0), throwsA(isA<AssertionError>()));
      expect(() => GeoPoint(0, 181), throwsA(isA<AssertionError>()));
    });
  });

  group('path length and nearest point', () {
    final path = [
      const GeoPoint(27, 88),
      destination(const GeoPoint(27, 88), bearing: 90, distanceM: 100),
      destination(
        destination(const GeoPoint(27, 88), bearing: 90, distanceM: 100),
        bearing: 0,
        distanceM: 100,
      ),
    ];

    test('pathLengthM sums the segments', () {
      expect(pathLengthM(path), closeTo(200, 0.5));
      expect(pathLengthM(const [GeoPoint(27, 88)]), 0);
      expect(pathLengthM(const []), 0);
    });

    test('nearestOnPath finds the closest vertex index and distance', () {
      final near = destination(path[1], bearing: 200, distanceM: 10);
      final n = nearestOnPath(path, near);
      expect(n.index, 1);
      expect(n.distanceM, closeTo(10, 0.5));
    });

    test('nearestOnPath on a single point returns that point', () {
      final n = nearestOnPath(const [
        GeoPoint(27, 88),
      ], const GeoPoint(27.001, 88));
      expect(n.index, 0);
    });

    test('nearestOnPath on an empty path throws', () {
      expect(
        () => nearestOnPath(const [], const GeoPoint(0, 0)),
        throwsArgumentError,
      );
    });
  });
}
