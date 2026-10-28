import 'package:core_geo/core_geo.dart';
import 'package:core_model/core_model.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 10, 27, 9);
const origin = GeoPoint(27.036, 88.2627);

/// A fix [meters] metres along [bearing] from the origin, [seconds] after t0.
LocationFix fix({
  double meters = 0,
  double bearing = 90,
  int seconds = 0,
  double accuracy = 6,
}) {
  final p = destination(origin, bearing: bearing, distanceM: meters);
  return LocationFix(
    latitude: p.lat,
    longitude: p.lon,
    accuracyM: accuracy,
    gpsTime: t0.add(Duration(seconds: seconds)),
  );
}

void main() {
  late FixFilter f;
  setUp(() => f = FixFilter());

  test('the first good fix is accepted', () {
    expect(f.check(fix()), FixVerdict.accepted);
  });

  test('a fix with poor accuracy is rejected, even the first', () {
    expect(f.check(fix(accuracy: 80)), FixVerdict.poorAccuracy);
    expect(
      f.check(fix(accuracy: 40)),
      FixVerdict.accepted,
      reason: 'at the limit',
    );
  });

  test('a move under the minimum is ignored (standing still, GPS jitter)', () {
    f.check(fix());
    expect(f.check(fix(meters: 4, seconds: 5)), FixVerdict.tooClose);
    expect(f.check(fix(meters: 9, seconds: 10)), FixVerdict.accepted);
  });

  test('small moves are measured from the last ACCEPTED fix, so slow drift '
      'is not lost', () {
    f.check(fix());
    expect(f.check(fix(meters: 5, seconds: 5)), FixVerdict.tooClose);
    expect(f.check(fix(meters: 10, seconds: 10)), FixVerdict.accepted);
  });

  test('an impossible speed is rejected (a GPS jump)', () {
    f.check(fix());
    // 900 m in 10 s = 90 m/s
    expect(f.check(fix(meters: 900, seconds: 10)), FixVerdict.impossibleSpeed);
  });

  test('walking speed is accepted', () {
    f.check(fix());
    expect(f.check(fix(meters: 30, seconds: 10)), FixVerdict.accepted);
  });

  test('a fix with the same or an earlier GPS time is out of order', () {
    f.check(fix(seconds: 10));
    expect(f.check(fix(meters: 50, seconds: 10)), FixVerdict.outOfOrder);
    expect(f.check(fix(meters: 50, seconds: 5)), FixVerdict.outOfOrder);
  });

  test('a rejected fix does not move the baseline', () {
    f.check(fix());
    f.check(fix(meters: 900, seconds: 10));
    expect(f.check(fix(meters: 20, seconds: 20)), FixVerdict.accepted);
  });

  test('if the baseline was the outlier, three jumps in a row re-sync', () {
    f.check(fix());
    expect(f.check(fix(meters: 5000, seconds: 10)), FixVerdict.impossibleSpeed);
    expect(f.check(fix(meters: 5010, seconds: 20)), FixVerdict.impossibleSpeed);
    expect(f.check(fix(meters: 5020, seconds: 30)), FixVerdict.accepted);
    expect(f.check(fix(meters: 5040, seconds: 40)), FixVerdict.accepted);
  });

  test('a good fix resets the jump counter', () {
    f.check(fix());
    f.check(fix(meters: 5000, seconds: 10));
    f.check(fix(meters: 5010, seconds: 20));
    expect(f.check(fix(meters: 25, seconds: 30)), FixVerdict.accepted);
    expect(f.check(fix(meters: 9000, seconds: 40)), FixVerdict.impossibleSpeed);
    expect(f.check(fix(meters: 9010, seconds: 50)), FixVerdict.impossibleSpeed);
  });

  test('thresholds are configurable', () {
    final strict = FixFilter(maxAccuracyM: 10, minMoveM: 20, maxSpeedMps: 5);
    expect(strict.check(fix(accuracy: 15)), FixVerdict.poorAccuracy);
    expect(strict.check(fix()), FixVerdict.accepted);
    expect(strict.check(fix(meters: 15, seconds: 10)), FixVerdict.tooClose);
    expect(
      strict.check(fix(meters: 100, seconds: 10)),
      FixVerdict.impossibleSpeed,
    );
  });

  test('reset forgets the baseline', () {
    f.check(fix());
    f.reset();
    expect(f.check(fix(meters: 3000, seconds: 1)), FixVerdict.accepted);
  });
}
