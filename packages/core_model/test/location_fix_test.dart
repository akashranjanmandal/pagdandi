import 'package:core_model/core_model.dart';
import 'package:test/test.dart';

LocationFix fix({double lat = 27.041, double lon = 88.2663, double acc = 6}) =>
    LocationFix(
      latitude: lat,
      longitude: lon,
      accuracyM: acc,
      gpsTime: DateTime.utc(2026, 10, 27, 9),
    );

void main() {
  test('fixes with equal fields are equal', () {
    expect(fix(), fix());
    expect(fix().hashCode, fix().hashCode);
    expect(fix(), isNot(fix(acc: 7)));
  });

  test('rejects out-of-range coordinates and negative accuracy', () {
    expect(() => fix(lat: 91), throwsA(isA<AssertionError>()));
    expect(() => fix(lon: -181), throwsA(isA<AssertionError>()));
    expect(() => fix(acc: -1), throwsA(isA<AssertionError>()));
  });

  test('optional fields default to null', () {
    final f = fix();
    expect(f.altitudeM, isNull);
    expect(f.speedMps, isNull);
    expect(f.bearingDeg, isNull);
  });
}
