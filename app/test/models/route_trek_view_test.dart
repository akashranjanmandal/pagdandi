import 'package:core_model/core_model.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:trek_core/trek_core.dart';

Route route() => Route(
  id: 'r',
  name: 'Lohajung-Brahmatal',
  points: [
    for (var i = 0; i <= 100; i++)
      RoutePoint(30 + i * 0.0001, 79, ele: 2000.0 + i),
  ],
  waypoints: const [Waypoint('Brahm Tal (Brahmatal)', 30.01, 79)],
  attribution: 'a',
);

NavView navView({
  DateTime? snoozedUntil,
  NavStatus status = NavStatus.onRoute,
  double progress = 400,
  double remaining = 600,
  double cross = 0,
  double bearing = 0,
  double? heading,
  String? nextName = 'Brahm Tal (Brahmatal)',
  double? nextDist = 600,
  bool arrived = false,
  bool reversed = false,
  double climbLeft = 60,
}) => NavView(
  routeId: 'r',
  routeName: 'Lohajung-Brahmatal',
  status: status,
  progressM: progress,
  remainingM: remaining,
  totalM: progress + remaining,
  crossTrackM: cross,
  bearingToGoDeg: bearing,
  headingDeg: heading,
  arrived: arrived,
  reversed: reversed,
  climbLeftM: climbLeft,
  snoozedUntil: snoozedUntil,
  nextName: nextName,
  nextDistM: nextDist,
);

CoreStateMessage msg(
  NavView? nav, {
  bool fix = true,
  Activity a = Activity.moving,
}) => CoreStateMessage(
  state: TrekState(activity: a, emergency: const NoEmergency(), mapOpen: false),
  sos: const SosSummary.none(),
  issues: const [],
  stats: const TrekStats(
    distanceM: 3000,
    climbM: 400,
    elapsed: Duration(hours: 2, minutes: 5),
    altitudeM: 2800,
  ),
  battery: 70,
  fix: fix
      ? LocationFix(
          latitude: 30.004,
          longitude: 79,
          accuracyM: 7,
          gpsTime: DateTime.utc(2026, 12, 14, 8),
          altitudeM: 2800,
        )
      : null,
  at: DateTime.utc(2026, 12, 14, 8),
  nav: nav,
);

void main() {
  test('on route: the hero is the distance to the next place', () {
    final v = ActiveTrekView.fromCore(msg(navView()), route: route());
    expect(v.nav, NavState.onRoute);
    expect(v.hero, '600 m');
    expect(v.sub, 'to Brahm Tal (Brahmatal)');
    expect(v.live, isTrue);
  });

  test('a long way to the next place is shown in km', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(nextDist: 5018, remaining: 5018)),
      route: route(),
    );
    expect(v.hero, '5.0 km');
  });

  test('past the last named place the hero is what is left', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(nextName: null, nextDist: null, remaining: 1500)),
      route: route(),
    );
    expect(v.hero, '1.5 km');
    expect(v.sub, 'to the end of Lohajung-Brahmatal');
  });

  test('the triplet is left, climb left and time on the trail', () {
    final v = ActiveTrekView.fromCore(msg(navView()), route: route());
    expect(
      [for (final s in v.stats) '${s.value} ${s.unit}'],
      [
        '600 m',
        '60 m',
        '2:05 h',
      ],
    );
    expect(
      [for (final s in v.stats) s.caption],
      ['left', 'climb left', 'time'],
    );
    expect(v.statsHeader, 'to Brahm Tal');
  });

  test('arrived says so plainly', () {
    final v = ActiveTrekView.fromCore(
      msg(
        navView(arrived: true, remaining: 10, nextName: null, nextDist: null),
      ),
      route: route(),
    );
    expect(v.hero, 'You have arrived');
    expect(v.sub, 'at Brahm Tal');
  });

  test('off route: how far, and which side the trail is on', () {
    final left = ActiveTrekView.fromCore(
      msg(
        navView(
          status: NavStatus.offRoute,
          cross: 42,
          bearing: 270,
          heading: 0,
        ),
      ),
      route: route(),
    );
    expect(left.nav, NavState.offRoute);
    expect(left.hero, '42 m off trail');
    expect(left.sub, 'turn back · trail is to your left');
    expect(left.dialAngle, closeTo(-90, 0.1));
    final right = ActiveTrekView.fromCore(
      msg(
        navView(status: NavStatus.offRoute, cross: 42, bearing: 90, heading: 0),
      ),
      route: route(),
    );
    expect(right.sub, 'turn back · trail is to your right');
  });

  test('off route without a heading names the compass direction', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(status: NavStatus.offRoute, cross: 42, bearing: 270)),
      route: route(),
    );
    expect(v.sub, 'head west to the trail');
    expect(v.dialAngle, closeTo(270, 0.1));
  });

  test('wrong way: turn around', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(status: NavStatus.wrongWay, heading: 180)),
      route: route(),
    );
    expect(v.nav, NavState.wrongWay);
    expect(v.hero, 'Heading back to start');
    expect(v.sub, 'turn around to continue');
  });

  test('wrong way on the way home says nothing about the start', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(status: NavStatus.wrongWay, reversed: true)),
      route: route(),
    );
    expect(v.hero, 'Heading the wrong way');
  });

  test('GPS lost keeps the guidance honest', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(status: NavStatus.gpsLost)),
      route: route(),
    );
    expect(v.nav, NavState.gpsLost);
    expect(v.hero, 'GPS signal weak');
    expect(v.sub, 'keep to the trail · distances paused');
  });

  test('the dial turns the shortest way to the bearing, from the heading', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(bearing: 10, heading: 350)),
      route: route(),
    );
    expect(v.dialAngle, closeTo(20, 0.1));
  });

  test('with a route chosen but no fix yet it waits for GPS', () {
    final v = ActiveTrekView.fromCore(msg(null, fix: false), route: route());
    expect(v.nav, NavState.gpsLost);
    expect(v.hero, 'Waiting for GPS');
    expect(v.sub, contains('Lohajung-Brahmatal'));
  });

  test('a free trek is unchanged by all this', () {
    final v = ActiveTrekView.fromCore(msg(null));
    expect(v.nav, NavState.free);
    expect(v.route, isNull);
  });

  test('the view carries the route and the walker for the map panel', () {
    final r = route();
    final v = ActiveTrekView.fromCore(msg(navView()), route: r);
    expect(v.route, same(r));
    expect(v.navView!.progressM, 400);
    expect(v.me, isNotNull);
  });

  test('a reversed trek heads for where it started', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(reversed: true, nextName: 'Lohajung', nextDist: 3000)),
      route: route().reversed(),
    );
    expect(v.sub, 'to Lohajung');
  });

  test('a snooze shows the time left, counting from when the message came', () {
    final v = ActiveTrekView.fromCore(
      msg(
        navView(
          status: NavStatus.offRoute,
          cross: 40,
          snoozedUntil: DateTime.utc(2026, 12, 14, 8, 10),
        ),
      ),
      route: route(),
      sinceReceived: const Duration(seconds: 30),
    );
    expect(v.snoozeLeft, const Duration(minutes: 9, seconds: 30));
  });

  test('no snooze, no countdown', () {
    final v = ActiveTrekView.fromCore(msg(navView()), route: route());
    expect(v.snoozeLeft, isNull);
  });

  test('a snooze that has run out shows nothing', () {
    final v = ActiveTrekView.fromCore(
      msg(navView(snoozedUntil: DateTime.utc(2026, 12, 14, 8, 1))),
      route: route(),
      sinceReceived: const Duration(minutes: 5),
    );
    expect(v.snoozeLeft, isNull);
  });
}
