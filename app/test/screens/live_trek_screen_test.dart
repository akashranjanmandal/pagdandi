import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/screens/active_trek_screen.dart';
import 'package:pagdandi_app/screens/trek_actions.dart';
import 'package:pagdandi_app/widgets/direction_dial.dart';
import 'package:trek_core/trek_core.dart';

import '../goldens/golden_harness.dart';
import '../goldens/live_view.dart';

void main() {
  testWidgets('a live trek shows the real position, not the sample map', (
    tester,
  ) async {
    await pumpPhone(tester, ActiveTrekScreen(view: live()));
    expect(find.text('27.0000° N  88.0000° E'), findsOneWidget);
    expect(find.text('RK'), findsNothing);
    expect(find.text('MD'), findsNothing);
  });

  testWidgets('a live solo trek offers no group radar and no push-to-talk', (
    tester,
  ) async {
    await pumpPhone(tester, ActiveTrekScreen(view: live()));
    expect(find.text('Hold to talk'), findsNothing);
    expect(find.textContaining('in range'), findsNothing);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Pin'), findsOneWidget);
  });

  testWidgets('the sample view still shows the designed map and group', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      ActiveTrekScreen(view: ActiveTrekView.sample(NavState.onRoute)),
    );
    expect(find.text('Hold to talk'), findsOneWidget);
    expect(find.text('4 of 4 in range'), findsOneWidget);
  });

  testWidgets('a live trek can be ended, but only with a 3 second hold', (
    tester,
  ) async {
    var ended = 0;
    await pumpPhone(
      tester,
      ActiveTrekScreen(
        view: live(),
        actions: TrekActions(onEndTrek: () => ended++),
      ),
    );
    await tester.tap(find.text('End trek · hold 3 s'));
    await tester.pump(const Duration(seconds: 5));
    expect(ended, 0, reason: 'a tap must never end the trek');
    final g = await tester.startGesture(
      tester.getCenter(find.text('End trek · hold 3 s')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3100));
    expect(ended, 1);
    await g.up();
  });

  testWidgets('the sample trek has no End trek key', (tester) async {
    await pumpPhone(
      tester,
      ActiveTrekScreen(view: ActiveTrekView.sample(NavState.onRoute)),
    );
    expect(find.textContaining('End trek'), findsNothing);
  });

  testWidgets('a free trek has no arrow pointing at nothing', (tester) async {
    await pumpPhone(tester, ActiveTrekScreen(view: live()));
    final dial = tester.widget<DirectionDial>(find.byType(DirectionDial));
    expect(dial.glyph, AppIcon.pin);
  });

  testWidgets('a route trek keeps its direction arrow', (tester) async {
    await pumpPhone(
      tester,
      ActiveTrekScreen(view: ActiveTrekView.sample(NavState.onRoute)),
    );
    final dial = tester.widget<DirectionDial>(find.byType(DirectionDial));
    expect(dial.glyph, isNull);
  });

  testWidgets('a revoked permission shows as a line on the live trek', (
    tester,
  ) async {
    final v = live(
      issues: const [
        IssueView(
          severity: 'critical',
          message: 'The sms permission is off',
          fixHint: 'Allow sms',
        ),
      ],
    );
    await pumpPhone(tester, ActiveTrekScreen(view: v));
    expect(find.text('The sms permission is off · Allow sms'), findsOneWidget);
  });

  testWidgets('the Pin key drops a pin and shows how many there are', (
    tester,
  ) async {
    var pins = 0;
    await pumpPhone(
      tester,
      ActiveTrekScreen(
        view: live(pinCount: 2),
        actions: TrekActions(onPin: () => pins++),
      ),
    );
    expect(find.text('Pin · 2'), findsOneWidget);
    await tester.tap(find.text('Pin · 2'));
    expect(pins, 1);
  });
}
