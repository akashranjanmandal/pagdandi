import 'package:engine_navigation/engine_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/route_summary.dart';

Route route() => Route(
  id: 'r',
  name: 'Lohajung-Brahmatal',
  points: [
    for (var i = 0; i <= 100; i++)
      RoutePoint(30.13 + i * 0.0005, 79.6, ele: 2373.0 + i * 8.4),
  ],
  waypoints: const [
    Waypoint('Lohajung', 30.13, 79.6),
    Waypoint('Bhengal Tal (Bekaltal)', 30.155, 79.6),
    Waypoint('Brahm Tal (Brahmatal)', 30.18, 79.6),
  ],
  attribution: 'OpenStreetMap contributors',
);

// India Standard Time.
const ist = Duration(hours: 5, minutes: 30);

void main() {
  final s = RouteSummary.of(
    route(),
    day: DateTime.utc(2026, 12, 14),
    utcOffset: ist,
  );

  test('length, climb and elevation range in words', () {
    expect(s.lengthText, '5.6 km');
    expect(s.climbText, '+840 m climb');
    expect(s.elevationText, '2,373 to 3,213 m');
  });

  test('places with their distance from the start', () {
    expect(s.places.map((p) => p.name), [
      'Lohajung',
      'Bhengal Tal (Bekaltal)',
      'Brahm Tal (Brahmatal)',
    ]);
    expect(s.places.first.kmText, '0.0 km');
    expect(s.places.last.kmText, '5.6 km');
  });

  test('sunrise and sunset in local time, 24 hour', () {
    final sun = s.sun!;
    expect(sun.sunriseText, matches(RegExp(r'^0[67]:\d\d$')));
    expect(sun.sunsetText, matches(RegExp(r'^17:\d\d$')));
  });

  test('the suggested turn-back time is three hours before sunset', () {
    final sun = s.sun!;
    final parts = sun.sunsetText.split(':').map(int.parse).toList();
    final back = sun.turnBackText.split(':').map(int.parse).toList();
    expect((parts[0] * 60 + parts[1]) - (back[0] * 60 + back[1]), 180);
  });

  test('the winter note appears in winter months only', () {
    expect(s.winterNote, isNotNull);
    expect(s.winterNote, contains('snow'));
    final june = RouteSummary.of(
      route(),
      day: DateTime.utc(2026, 6, 14),
      utcOffset: ist,
    );
    expect(june.winterNote, isNull);
    for (final m in [11, 12, 1, 2]) {
      expect(
        RouteSummary.of(
          route(),
          day: DateTime.utc(2026, m, 10),
          utcOffset: ist,
        ).winterNote,
        isNotNull,
        reason: 'month $m',
      );
    }
  });

  test('says where the data comes from', () {
    expect(s.attribution, 'OpenStreetMap contributors');
  });

  test('a route without elevation has no climb or range claim', () {
    final flat = Route(
      id: 'f',
      name: 'F',
      points: const [RoutePoint(30, 79), RoutePoint(30.01, 79)],
      attribution: 'a',
    );
    final f = RouteSummary.of(
      flat,
      day: DateTime.utc(2026, 12, 14),
      utcOffset: ist,
    );
    expect(f.climbText, isNull);
    expect(f.elevationText, isNull);
  });

  test('a day when the sun does not set has no sun times, not wrong ones', () {
    final polar = Route(
      id: 'p',
      name: 'P',
      points: const [RoutePoint(80, 0), RoutePoint(80.01, 0)],
      attribution: 'a',
    );
    final p = RouteSummary.of(
      polar,
      day: DateTime.utc(2026, 6, 21),
      utcOffset: Duration.zero,
    );
    expect(p.sun, isNull);
  });
}
