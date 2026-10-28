import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';

import '../goldens/golden_harness.dart';

void main() {
  testWidgets('SOS screen shows no Beacon row without a real beacon', (
    tester,
  ) async {
    await pumpPhone(tester, const SosActiveScreen(view: SosView()));
    expect(find.text('Beacon'), findsNothing);
    expect(find.textContaining('beacon'), findsNothing);
  });

  testWidgets('SOS screen shows the Beacon row when one is running', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      const SosActiveScreen(
        view: SosView(
          delivery: SosDelivery(total: 3, delivered: 0, beacon: true),
        ),
      ),
    );
    expect(find.text('Beacon'), findsOneWidget);
  });

  testWidgets('SOS with no contacts says nobody will be messaged', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      const SosActiveScreen(
        view: SosView(delivery: SosDelivery(total: 0, delivered: 0)),
      ),
    );
    expect(find.text('No contacts to message · call for help'), findsOneWidget);
    expect(find.textContaining('0 contacts'), findsNothing);
  });

  testWidgets('Lost mode does not claim a beacon that is not built', (
    tester,
  ) async {
    await pumpPhone(tester, const LostModeScreen(view: LostView()));
    expect(find.text('Beacon broadcasting'), findsNothing);
  });

  testWidgets('Fall countdown does not claim a beacon either', (tester) async {
    await pumpPhone(
      tester,
      const FallCountdownScreen(view: FallView(stage: FallStage.sent)),
    );
    expect(find.textContaining('beacon'), findsNothing);
  });
}
