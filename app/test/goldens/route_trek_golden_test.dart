import 'dart:io';

import 'package:core_model/core_model.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/screens/active_trek_screen.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';
import 'package:trek_core/trek_core.dart';

import 'golden_harness.dart';

Route brahmatal() => parseGpx(
  File('assets/routes/lohajung_brahmatal.gpx').readAsStringSync(),
  id: 'lohajung-brahmatal',
);

ActiveTrekView view(
  Route r,
  double progress, {
  NavStatus status = NavStatus.onRoute,
  double cross = 0,
  double? heading,
  bool arrived = false,
  bool reversed = false,
}) {
  final at = r.positionAt(progress);
  final next = r.checkpoints.where((c) => c.distanceAlongM > progress + 25);
  final nv = NavView(
    routeId: r.id,
    routeName: r.name,
    status: status,
    progressM: progress,
    remainingM: r.totalM - progress,
    totalM: r.totalM,
    crossTrackM: cross,
    bearingToGoDeg: 20,
    headingDeg: heading,
    arrived: arrived,
    reversed: reversed,
    climbLeftM: r.climbRemainingM(progress),
    nextName: next.isEmpty ? null : next.first.name,
    nextDistM: next.isEmpty ? null : next.first.distanceAlongM - progress,
  );
  return ActiveTrekView.fromCore(
    CoreStateMessage(
      state: const TrekState(
        activity: Activity.moving,
        emergency: NoEmergency(),
        mapOpen: false,
      ),
      sos: const SosSummary.none(),
      issues: const [],
      stats: const TrekStats(
        distanceM: 6000,
        climbM: 800,
        elapsed: Duration(hours: 3, minutes: 40),
        altitudeM: 3040,
      ),
      battery: 71,
      fix: LocationFix(
        latitude: at.lat + (cross > 0 ? 0.0004 : 0),
        longitude: at.lon + (cross > 0 ? 0.0004 : 0),
        accuracyM: 6,
        gpsTime: DateTime.utc(2026, 12, 14, 8),
        altitudeM: 3040,
      ),
      at: DateTime.utc(2026, 12, 14, 8),
      nav: nv,
    ),
    route: r,
  );
}

void main() {
  final r = brahmatal();
  void shot(
    String name,
    ActiveTrekView v, {
    UiPrefs prefs = const UiPrefs(reduceMotion: true),
    double textScale = 1,
  }) {
    testWidgets(name, (tester) async {
      await pumpPhone(
        tester,
        ActiveTrekScreen(view: v),
        prefs: prefs,
        textScale: textScale,
      );
      await expectLater(
        find.byType(ActiveTrekScreen),
        matchesGoldenFile('route/$name.png'),
      );
    });
  }

  group('Brahmatal on the trek screen', () {
    shot('on_route_start', view(r, 120, heading: 20));
    shot('on_route_mid', view(r, 4300, heading: 15));
    shot('past_bekaltal', view(r, 7600, heading: 30));
    shot(
      'off_route',
      view(r, 6200, status: NavStatus.offRoute, cross: 48, heading: 0),
    );
    shot('wrong_way', view(r, 6200, status: NavStatus.wrongWay, heading: 200));
    shot('gps_lost', view(r, 6200, status: NavStatus.gpsLost));
    shot('arrived', view(r, 10560, arrived: true));
    shot(
      'sunlight',
      view(r, 4300, heading: 15),
      prefs: const UiPrefs(sunlight: true, reduceMotion: true),
    );
    shot('text_1_5', view(r, 4300, heading: 15), textScale: 1.5);
  });
}
