import 'package:core_geo/core_geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/routes/route_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const lib = AssetRouteLibrary();

  test('the Brahmatal route is bundled and listed', () {
    expect(lib.available.map((r) => r.id), contains('lohajung-brahmatal'));
    expect(lib.available.first.name, 'Lohajung to Brahmatal');
  });

  test('an unknown route id is null, not an error', () async {
    expect(await lib.load('nowhere'), isNull);
    expect(await lib.load(''), isNull);
  });

  group('the shipped Lohajung to Brahmatal file', () {
    test('has the right size, climb and places', () async {
      final r = (await lib.load('lohajung-brahmatal'))!;
      expect(r.totalM, inInclusiveRange(10500, 11000));
      expect(r.climbM, inInclusiveRange(1300, 1550));
      expect(r.hasElevation, isTrue);
      expect(r.checkpoints.map((c) => c.name), [
        'Lohajung',
        'Bhengal Tal (Bekaltal)',
        'Brahm Tal (Brahmatal)',
      ]);
      expect(r.checkpoints[1].distanceAlongM, inInclusiveRange(5300, 5800));
    });

    test('starts at Lohajung and ends at Brahm Tal', () async {
      final r = (await lib.load('lohajung-brahmatal'))!;
      expect(
        distanceM(r.geo.first, const GeoPoint(30.1285, 79.619)),
        lessThan(150),
      );
      expect(
        distanceM(r.geo.last, const GeoPoint(30.177, 79.5895)),
        lessThan(250),
      );
    });

    test(
      'elevations are in the mountains and rise from start to end',
      () async {
        final r = (await lib.load('lohajung-brahmatal'))!;
        final eles = r.points.map((p) => p.ele!).toList();
        expect(eles.first, inInclusiveRange(2200, 2500));
        expect(eles.last, inInclusiveRange(3100, 3400));
        expect(eles.reduce((a, b) => a < b ? a : b), greaterThan(2000));
        expect(eles.reduce((a, b) => a > b ? a : b), lessThan(3600));
      },
    );

    test('has no hole: neighbouring points are never far apart', () async {
      final r = (await lib.load('lohajung-brahmatal'))!;
      for (var i = 1; i < r.geo.length; i++) {
        expect(
          distanceM(r.geo[i - 1], r.geo[i]),
          lessThan(120),
          reason: 'point $i',
        );
      }
    });

    test('credits OpenStreetMap, as its licence requires', () async {
      final r = (await lib.load('lohajung-brahmatal'))!;
      expect(r.attribution, contains('OpenStreetMap'));
    });
  });
}
