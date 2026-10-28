import 'package:engine_navigation/engine_navigation.dart';
import 'package:test/test.dart';

void main() {
  // Brahmatal area, 14 December 2026.
  final day = DateTime.utc(2026, 12, 14);
  const lat = 30.15;
  const lon = 79.6;

  test('December sunset near Brahmatal is about 17:10 IST (11:40 UTC)', () {
    final t = sunTimes(day, lat, lon)!;
    final utcMin = t.sunset.hour * 60 + t.sunset.minute;
    // Hand calculation: solar noon 06:36 UTC, half-day 5.1 h => 11:42 UTC.
    expect(utcMin, inInclusiveRange(11 * 60 + 32, 11 * 60 + 52));
  });

  test('December sunrise is about 07:00 IST (01:30 UTC)', () {
    final t = sunTimes(day, lat, lon)!;
    final utcMin = t.sunrise.hour * 60 + t.sunrise.minute;
    expect(utcMin, inInclusiveRange(60 + 20, 60 + 40));
  });

  test('a December day at 30 N is about 10 hours long', () {
    final t = sunTimes(day, lat, lon)!;
    final h = t.sunset.difference(t.sunrise).inMinutes / 60;
    expect(h, inInclusiveRange(10.0, 10.5));
  });

  test('the June day is much longer than the December day', () {
    final dec = sunTimes(day, lat, lon)!;
    final jun = sunTimes(DateTime.utc(2026, 6, 21), lat, lon)!;
    expect(
      jun.sunset.difference(jun.sunrise).inHours,
      greaterThan(dec.sunset.difference(dec.sunrise).inHours + 2),
    );
  });

  test('times are UTC and fall on the given date', () {
    final t = sunTimes(day, lat, lon)!;
    expect(t.sunrise.isUtc, isTrue);
    expect(t.sunset.day, 14);
    expect(t.sunset.isAfter(t.sunrise), isTrue);
  });

  test('polar night and midnight sun have no sunrise', () {
    expect(sunTimes(DateTime.utc(2026, 12, 21), 80, 0), isNull);
    expect(sunTimes(DateTime.utc(2026, 6, 21), 80, 0), isNull);
  });

  test('the minutes before sunset can be counted', () {
    final t = sunTimes(day, lat, lon)!;
    final at = t.sunset.subtract(const Duration(minutes: 90));
    expect(t.untilSunset(at), const Duration(minutes: 90));
    expect(
      t.untilSunset(t.sunset.add(const Duration(minutes: 5))),
      const Duration(minutes: -5),
    );
  });
}
