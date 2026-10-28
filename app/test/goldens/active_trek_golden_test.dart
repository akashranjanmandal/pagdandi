import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/screens/active_trek_screen.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

import 'golden_harness.dart';
import 'live_view.dart';

void main() {
  group('Active Trek states', () {
    for (final nav in NavState.values) {
      testWidgets(nav.name, (tester) async {
        await pumpPhone(
          tester,
          ActiveTrekScreen(
            view: nav == NavState.free ? live() : ActiveTrekView.sample(nav),
          ),
        );
        await expectLater(
          find.byType(ActiveTrekScreen),
          matchesGoldenFile('active_trek/${nav.name}.png'),
        );
      });
    }
  });

  group('Active Trek variants', () {
    testWidgets('stationary', (tester) async {
      await pumpPhone(
        tester,
        ActiveTrekScreen(
          view: ActiveTrekView.sample(NavState.onRoute, stationary: true),
        ),
      );
      await expectLater(
        find.byType(ActiveTrekScreen),
        matchesGoldenFile('active_trek/stationary.png'),
      );
    });

    testWidgets('with a quick-message toast', (tester) async {
      await pumpPhone(
        tester,
        ActiveTrekScreen(
          view: ActiveTrekView.sample(
            NavState.onRoute,
            toast: const ToastMessage('Rahul', 'Take left fork'),
          ),
        ),
      );
      await expectLater(
        find.byType(ActiveTrekScreen),
        matchesGoldenFile('active_trek/toast.png'),
      );
    });

    testWidgets('off route, snoozed', (tester) async {
      await pumpPhone(
        tester,
        ActiveTrekScreen(
          view: ActiveTrekView.sample(
            NavState.offRoute,
            snoozeLeft: const Duration(minutes: 9, seconds: 58),
          ),
        ),
      );
      await expectLater(
        find.byType(ActiveTrekScreen),
        matchesGoldenFile('active_trek/off_route_snoozed.png'),
      );
    });

    for (final s in PttState.values.where((s) => s != PttState.idle)) {
      testWidgets('ptt ${s.name}', (tester) async {
        await pumpPhone(
          tester,
          ActiveTrekScreen(
            view: ActiveTrekView.sample(NavState.onRoute, ptt: s),
          ),
        );
        await expectLater(
          find.byType(ActiveTrekScreen),
          matchesGoldenFile('active_trek/ptt_${s.name}.png'),
        );
      });
    }
  });

  group('Active Trek preferences', () {
    final cases = {
      'left_handed': (const UiPrefs(leftHanded: true, reduceMotion: true), 1.0),
      'sunlight': (const UiPrefs(sunlight: true, reduceMotion: true), 1.0),
      'glove': (const UiPrefs(glove: true, reduceMotion: true), 1.0),
      'text_1_5': (const UiPrefs(reduceMotion: true), 1.5),
      'left_sunlight_text_1_5': (
        const UiPrefs(leftHanded: true, sunlight: true, reduceMotion: true),
        1.5,
      ),
    };
    for (final e in cases.entries) {
      testWidgets(e.key, (tester) async {
        await pumpPhone(
          tester,
          ActiveTrekScreen(view: ActiveTrekView.sample(NavState.junction)),
          prefs: e.value.$1,
          textScale: e.value.$2,
        );
        await expectLater(
          find.byType(ActiveTrekScreen),
          matchesGoldenFile('active_trek/${e.key}.png'),
        );
      });
    }
  });

  testWidgets('layout never overflows at text scale 1.5 in any state', (
    tester,
  ) async {
    for (final nav in NavState.values) {
      await pumpPhone(
        tester,
        ActiveTrekScreen(view: ActiveTrekView.sample(nav)),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull, reason: nav.name);
    }
  });
}
