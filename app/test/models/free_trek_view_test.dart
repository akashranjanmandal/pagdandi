import 'package:core_model/core_model.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:trek_core/trek_core.dart';

CoreStateMessage msg({
  List<IssueView> issues = const [],
  Activity activity = Activity.moving,
  double distance = 2400,
  Duration elapsed = const Duration(hours: 2, minutes: 10),
  LocationFix? fix,
  double climb = 320,
  int battery = 78,
}) => CoreStateMessage(
  state: TrekState(
    activity: activity,
    emergency: const NoEmergency(),
    mapOpen: false,
  ),
  sos: const SosSummary.none(),
  issues: issues,
  stats: TrekStats(
    distanceM: distance,
    climbM: climb,
    elapsed: elapsed,
    altitudeM: fix?.altitudeM,
  ),
  battery: battery,
  fix: fix,
  at: DateTime.utc(2026, 10, 28, 8),
);

LocationFix fix({double acc = 6, double? alt = 3214}) => LocationFix(
  latitude: 27,
  longitude: 88,
  accuracyM: acc,
  gpsTime: DateTime.utc(2026, 10, 28, 8),
  altitudeM: alt,
);

void main() {
  liveViewTests();
  test('free trek has its own tag, distinct from every route state', () {
    expect(NavState.free.tagLabel, 'Tracking');
    final labels = NavState.values.map((s) => s.tagLabel).toSet();
    expect(labels.length, NavState.values.length);
  });

  test('with a fix and no route, the hero is the distance walked', () {
    final v = ActiveTrekView.fromCore(msg(fix: fix()));
    expect(v.nav, NavState.free);
    expect(v.hero, '2.4 km');
    expect(v.statsHeader, 'so far');
    expect(v.accuracy, 'GPS ±6 m');
    expect(v.altitude, '3,214 m');
    expect(v.battery, 78);
  });

  test('short distances are shown in metres', () {
    expect(
      ActiveTrekView.fromCore(msg(distance: 420, fix: fix())).hero,
      '420 m',
    );
    expect(ActiveTrekView.fromCore(msg(distance: 0, fix: fix())).hero, '0 m');
  });

  test('the triplet is distance, climb and time', () {
    final s = ActiveTrekView.fromCore(msg(fix: fix())).stats;
    expect(
      [for (final x in s) '${x.value} ${x.unit}'],
      [
        '2.4 km',
        '320 m',
        '2:10 h',
      ],
    );
    expect([for (final x in s) x.caption], ['distance', 'climb', 'time']);
  });

  test('no fix yet shows GPS lost, honestly, never a made-up position', () {
    final v = ActiveTrekView.fromCore(msg());
    expect(v.nav, NavState.gpsLost);
    expect(v.accuracy, 'GPS ±—');
    expect(v.altitude, '—');
    expect(v.hero, 'Waiting for GPS');
  });

  test('standing still pauses the numbers', () {
    expect(
      ActiveTrekView.fromCore(
        msg(activity: Activity.stationary, fix: fix()),
      ).stationary,
      isTrue,
    );
  });

  test('there is no group in this build, and it says so plainly', () {
    final v = ActiveTrekView.fromCore(msg(fix: fix()));
    expect(v.groupMain, 'Solo');
  });

  test('an hour of climbing shows hours and zero-padded minutes', () {
    final v = ActiveTrekView.fromCore(
      msg(fix: fix(), elapsed: const Duration(hours: 1, minutes: 5)),
    );
    expect(v.stats[2].value, '1:05');
  });
}

void liveViewTests() {
  test('a critical health issue is shown on the trek, worst first', () {
    final v = ActiveTrekView.fromCore(
      msg(
        fix: fix(),
        issues: const [
          IssueView(
            severity: 'critical',
            message: 'The sms permission is off',
            fixHint: 'Allow sms',
          ),
          IssueView(severity: 'warn', message: 'Battery 12%', fixHint: 'Save'),
        ],
      ),
    );
    expect(v.alert, 'The sms permission is off · Allow sms');
  });

  test('warnings alone do not interrupt the trek screen', () {
    final v = ActiveTrekView.fromCore(
      msg(
        fix: fix(),
        issues: const [
          IssueView(severity: 'warn', message: 'Battery 12%', fixHint: 'Save'),
        ],
      ),
    );
    expect(v.alert, isNull);
  });

  test('no issues, no alert', () {
    expect(ActiveTrekView.fromCore(msg(fix: fix())).alert, isNull);
  });

  test('a view from the core is marked live and shows the real position', () {
    final v = ActiveTrekView.fromCore(msg(fix: fix()));
    expect(v.live, isTrue);
    expect(v.position, '27.0000° N  88.0000° E');
  });

  test('southern and western positions use S and W', () {
    final f = LocationFix(
      latitude: -33.5,
      longitude: -70.25,
      accuracyM: 5,
      gpsTime: DateTime.utc(2026, 10, 28),
    );
    expect(
      ActiveTrekView.fromCore(msg(fix: f)).position,
      '33.5000° S  70.2500° W',
    );
  });

  test('no fix, no position', () {
    expect(ActiveTrekView.fromCore(msg()).position, isNull);
  });

  test('the pin count comes from the core', () {
    final m = CoreStateMessage(
      state: msg().state,
      sos: msg().sos,
      issues: const [],
      stats: msg().stats,
      battery: 70,
      fix: fix(),
      at: DateTime.utc(2026, 10, 28, 8),
      pinCount: 4,
    );
    expect(ActiveTrekView.fromCore(m).pinCount, 4);
  });

  test('the sample view is not live', () {
    expect(ActiveTrekView.sample(NavState.onRoute).live, isFalse);
  });
}
