import 'package:core_model/core_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/position.dart';

LocationFix fix({
  double lat = 27.041,
  double lon = 88.2663,
  double acc = 8,
  double? alt = 3102,
}) => LocationFix(
  latitude: lat,
  longitude: lon,
  accuracyM: acc,
  gpsTime: DateTime.utc(2026, 10, 28, 14, 32, 9),
  altitudeM: alt,
);

void main() {
  test('formats a northern, eastern fix', () {
    final p = ShownPosition.fromFix(fix());
    expect(p.latText, '27.0410° N');
    expect(p.lonText, '88.2663° E');
    expect(p.altitudeText, '3,102');
    expect(p.accuracyText, 'GPS ±8 m');
    expect(p.timeText, 'GPS time 14:32 UTC');
  });

  test('southern and western use S and W and a positive number', () {
    final p = ShownPosition.fromFix(fix(lat: -33.5, lon: -70.25));
    expect(p.latText, '33.5000° S');
    expect(p.lonText, '70.2500° W');
  });

  test('no altitude is shown as unknown, never zero', () {
    expect(ShownPosition.fromFix(fix(alt: null)).altitudeText, '—');
  });

  test('accuracy is rounded to whole metres', () {
    expect(ShownPosition.fromFix(fix(acc: 7.6)).accuracyText, 'GPS ±8 m');
  });

  test('spoken form reads latitude, longitude and altitude in words', () {
    expect(
      ShownPosition.fromFix(fix()).spoken,
      'Latitude 27.0410 north, longitude 88.2663 east, altitude 3102 metres',
    );
  });
}
