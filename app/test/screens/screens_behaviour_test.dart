import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/screens/active_trek_screen.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/friend_sos_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';
import 'package:pagdandi_app/screens/trek_actions.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

import '../goldens/golden_harness.dart';

void main() {
  group('Active Trek', () {
    testWidgets('SOS starts only after a 3 second hold', (tester) async {
      var started = 0;
      final ticks = <int>[];
      await pumpPhone(
        tester,
        ActiveTrekScreen(
          view: ActiveTrekView.sample(NavState.onRoute),
          actions: TrekActions(
            onSosStarted: () => started++,
            onSosHoldTick: ticks.add,
          ),
        ),
      );
      await tester.tap(find.text('SOS'));
      await tester.pump(const Duration(seconds: 5));
      expect(started, 0, reason: 'a tap must never start SOS');

      final g = await tester.startGesture(tester.getCenter(find.text('SOS')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2900));
      expect(started, 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(started, 1);
      expect(ticks, [1, 2]);
      await g.up();
    });

    testWidgets(
      'the SOS key sits on the far side from PTT, mirrored for left hand',
      (tester) async {
        await pumpPhone(
          tester,
          ActiveTrekScreen(view: ActiveTrekView.sample(NavState.onRoute)),
        );
        final sosRight = tester.getCenter(find.text('SOS')).dx;
        final pttRight = tester.getCenter(find.text('Hold to talk')).dx;
        expect(sosRight, lessThan(pttRight));
        await pumpPhone(
          tester,
          ActiveTrekScreen(view: ActiveTrekView.sample(NavState.onRoute)),
          prefs: const UiPrefs(leftHanded: true, reduceMotion: true),
        );
        expect(
          tester.getCenter(find.text('SOS')).dx,
          greaterThan(tester.getCenter(find.text('Hold to talk')).dx),
        );
      },
    );

    testWidgets('snooze appears only when off route', (tester) async {
      await pumpPhone(
        tester,
        ActiveTrekScreen(view: ActiveTrekView.sample(NavState.onRoute)),
      );
      expect(find.text('I know, exploring'), findsNothing);
      await pumpPhone(
        tester,
        ActiveTrekScreen(view: ActiveTrekView.sample(NavState.offRoute)),
      );
      expect(find.text('I know, exploring'), findsOneWidget);
    });

    testWidgets('the hero never repeats a number from the to-camp triplet', (
      tester,
    ) async {
      for (final nav in NavState.values) {
        final v = ActiveTrekView.sample(nav);
        expect(
          v.stats.map((s) => '${s.value} ${s.unit}'),
          isNot(contains(v.hero)),
        );
      }
    });

    testWidgets('every interactive control is in the bottom 40 percent', (
      tester,
    ) async {
      await pumpPhone(
        tester,
        ActiveTrekScreen(view: ActiveTrekView.sample(NavState.onRoute)),
      );
      for (final t in ['SOS', 'Pin', 'Hold to talk', '4 of 4 in range']) {
        expect(
          tester.getCenter(find.text(t)).dy,
          greaterThan(780 * 0.6),
          reason: t,
        );
      }
    });
  });

  group('SOS active', () {
    testWidgets('headline follows the delivery truth', (tester) async {
      for (final (delivered, headline) in [
        (0, 'SOS active'),
        (2, 'SOS delivered to 2 of 3'),
        (3, 'SOS delivered'),
      ]) {
        await pumpPhone(
          tester,
          SosActiveScreen(
            view: SosView(
              delivery: SosDelivery(total: 3, delivered: delivered),
            ),
          ),
        );
        expect(find.text(headline), findsOneWidget);
      }
    });

    testWidgets('Call 112 is disabled without signal and says why', (
      tester,
    ) async {
      var calls = 0;
      await pumpPhone(
        tester,
        SosActiveScreen(view: const SosView(), onCall: () => calls++),
      );
      expect(
        find.text('No signal. Enables when any signal appears.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Call 112'));
      expect(calls, 0);
      await pumpPhone(
        tester,
        SosActiveScreen(
          view: const SosView(signal: true),
          onCall: () => calls++,
        ),
      );
      await tester.tap(find.text('Call 112'));
      expect(calls, 1);
    });

    testWidgets('cancelling needs a 5 second hold', (tester) async {
      var cancelled = 0;
      await pumpPhone(
        tester,
        SosActiveScreen(view: const SosView(), onCancel: () => cancelled++),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byType(HoldButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(cancelled, 0);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(cancelled, 1);
      await g.up();
    });

    testWidgets('siren and torch toggles ask for the opposite value', (
      tester,
    ) async {
      final asked = <String>[];
      await pumpPhone(
        tester,
        SosActiveScreen(
          view: const SosView(),
          onSiren: (v) => asked.add('siren $v'),
          onTorch: (v) => asked.add('torch $v'),
        ),
      );
      await tester.tap(find.text('Siren'));
      await tester.tap(find.text('Torch strobe'));
      expect(asked, ['siren true', 'torch true']);
    });
  });

  group('Fall countdown', () {
    testWidgets('I am OK is a single tap', (tester) async {
      var ok = 0;
      await pumpPhone(
        tester,
        FallCountdownScreen(view: const FallView(), onOk: () => ok++),
      );
      await tester.tap(find.text('I’m OK'));
      expect(ok, 1);
    });

    testWidgets('sending SOS now needs a hold, not a tap', (tester) async {
      var sent = 0;
      await pumpPhone(
        tester,
        FallCountdownScreen(view: const FallView(), onSendNow: () => sent++),
      );
      await tester.tap(find.text('Send SOS now · hold 3 s'));
      await tester.pump(const Duration(seconds: 4));
      expect(sent, 0);
    });

    testWidgets('the OK key is the biggest control on the screen', (
      tester,
    ) async {
      await pumpPhone(tester, const FallCountdownScreen(view: FallView()));
      final ok = tester.getSize(
        find.bySemanticsLabel("I'm OK. Cancel the SOS"),
      );
      final sos = tester.getSize(find.byType(HoldButton));
      expect(ok.width * ok.height, greaterThan(sos.width * sos.height * 4));
    });

    testWidgets('shows the seconds left', (tester) async {
      await pumpPhone(
        tester,
        const FallCountdownScreen(view: FallView(secondsLeft: 47)),
      );
      expect(find.text('47'), findsOneWidget);
    });
  });

  group('Friend SOS', () {
    testWidgets('Call 112 follows signal; Guide me there acknowledges', (
      tester,
    ) async {
      var guided = 0;
      await pumpPhone(
        tester,
        FriendSosScreen(view: const FriendSosView(), onGuide: () => guided++),
      );
      expect(find.text('No signal yet'), findsOneWidget);
      await tester.tap(find.text('Guide me there'));
      expect(guided, 1);
    });

    testWidgets('the card sheet lists blood group, allergies and contact', (
      tester,
    ) async {
      await pumpPhone(
        tester,
        const FriendSosScreen(view: FriendSosView(cardOpen: true)),
      );
      for (final t in ['B+', 'Penicillin', 'Meera · +91 98xxx xx210']) {
        expect(find.text(t), findsOneWidget);
      }
    });

    testWidgets('out of range uses the out-of-range wording, not SOS', (
      tester,
    ) async {
      await pumpPhone(
        tester,
        const FriendSosScreen(view: FriendSosView(kind: FriendKind.outOfRange)),
      );
      expect(find.text('Rahul out of range'), findsOneWidget);
      expect(find.text('Rahul sent SOS'), findsNothing);
    });
  });

  group('Lost mode', () {
    testWidgets('group row stays honest until the group is reached', (
      tester,
    ) async {
      await pumpPhone(tester, const LostModeScreen(view: LostView()));
      expect(find.text('when in range'), findsOneWidget);
      await pumpPhone(
        tester,
        const LostModeScreen(view: LostView(groupReached: true)),
      );
      expect(find.text('3 received'), findsOneWidget);
    });

    testWidgets('choosing a reason reports it', (tester) async {
      LostReason? got;
      await pumpPhone(
        tester,
        LostModeScreen(
          view: const LostView(stage: LostStage.prompt),
          onReason: (r) => got = r,
        ),
      );
      await tester.tap(find.text('Getting dark'));
      expect(got, LostReason.dark);
    });

    testWidgets("I'm found needs a 3 second hold", (tester) async {
      var found = 0;
      await pumpPhone(
        tester,
        LostModeScreen(view: const LostView(), onFound: () => found++),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byType(HoldButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(found, 0);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(found, 1);
      await g.up();
    });
  });
}
