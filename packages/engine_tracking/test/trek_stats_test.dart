import 'package:core_geo/core_geo.dart';
import 'package:core_model/core_model.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 10, 27, 9);
const origin = GeoPoint(27, 88);

LocationFix at(double meters, int seconds, {double? alt}) {
  final p = destination(origin, bearing: 90, distanceM: meters);
  return LocationFix(
    latitude: p.lat,
    longitude: p.lon,
    accuracyM: 5,
    gpsTime: t0.add(Duration(seconds: seconds)),
    altitudeM: alt,
  );
}

void main() {
  test('an empty breadcrumb has zero stats', () {
    final s = computeStats(const []);
    expect(s.distanceM, 0);
    expect(s.climbM, 0);
    expect(s.elapsed, Duration.zero);
    expect(s.altitudeM, isNull);
  });

  test('distance is the sum of the segments', () {
    final s = computeStats([at(0, 0), at(100, 60), at(250, 120)]);
    expect(s.distanceM, closeTo(250, 1));
  });

  test('elapsed is first fix to last fix', () {
    expect(
      computeStats([at(0, 0), at(50, 600)]).elapsed,
      const Duration(minutes: 10),
    );
  });

  test('current altitude is the last known altitude', () {
    expect(
      computeStats([at(0, 0, alt: 3000), at(50, 60, alt: 3040), at(60, 90)])
          .altitudeM,
      3040,
    );
  });

  test('climb adds up only real ascents', () {
    final s = computeStats([
      at(0, 0, alt: 3000),
      at(100, 60, alt: 3050), // +50
      at(200, 120, alt: 3020), // down, ignored
      at(300, 180, alt: 3080), // +60 from 3020
    ]);
    expect(s.climbM, closeTo(110, 0.001));
  });

  test('altitude noise under 3 m is not counted as climb', () {
    final s = computeStats([
      at(0, 0, alt: 3000),
      at(20, 10, alt: 3001.5),
      at(40, 20, alt: 2999.5),
      at(60, 30, alt: 3002),
    ]);
    expect(s.climbM, 0);
  });

  test('a slow steady climb of small steps still counts once it adds up', () {
    final s = computeStats([
      for (var i = 0; i <= 10; i++) at(i * 20.0, i * 10, alt: 3000 + i * 2.0),
    ]);
    expect(s.climbM, closeTo(20, 2));
  });

  test('fixes without altitude are skipped for climb, not treated as zero', () {
    final s = computeStats([
      at(0, 0, alt: 3000),
      at(50, 10),
      at(100, 20, alt: 3030),
    ]);
    expect(s.climbM, closeTo(30, 0.001));
  });

  test('a single fix has no distance, climb or time', () {
    final s = computeStats([at(0, 0, alt: 3000)]);
    expect(s.distanceM, 0);
    expect(s.elapsed, Duration.zero);
    expect(s.altitudeM, 3000);
  });
}
