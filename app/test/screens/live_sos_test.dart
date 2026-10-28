import 'package:core_model/core_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/position.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';

import '../goldens/golden_harness.dart';

ShownPosition real() => ShownPosition.fromFix(
  LocationFix(
    latitude: 12.3456,
    longitude: 77.6543,
    accuracyM: 5,
    gpsTime: DateTime.utc(2026, 10, 28, 9, 7),
    altitudeM: 910,
  ),
);

void main() {
  lostTests();
  testWidgets('a live SOS shows the real position and none of the sample', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      SosActiveScreen(
        view: SosView(
          delivery: const SosDelivery(total: 2, delivered: 0),
          position: real(),
          battery: 63,
        ),
      ),
    );
    expect(find.textContaining('12.3456° N'), findsOneWidget);
    expect(find.textContaining('77.6543° E'), findsOneWidget);
    expect(find.textContaining('910', findRichText: true), findsOneWidget);
    expect(find.text('GPS ±5 m'), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
    expect(find.textContaining('27.0410'), findsNothing);
    expect(find.textContaining('3,102', findRichText: true), findsNothing);
    expect(find.textContaining('14:32'), findsNothing);
    expect(find.textContaining('41%'), findsNothing);
  });

  testWidgets('with no GPS fix the SOS screen says so instead of guessing', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      const SosActiveScreen(
        view: SosView(
          delivery: SosDelivery(total: 2, delivered: 0),
          position: null,
          battery: 63,
        ),
      ),
    );
    expect(find.text('Waiting for GPS'), findsOneWidget);
    expect(find.textContaining('27.0410'), findsNothing);
    expect(find.text('GPS ±—'), findsOneWidget);
  });

  testWidgets('the sent-SOS fall screen shows the real accuracy and battery', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      const FallCountdownScreen(
        view: FallView(
          stage: FallStage.sent,
          accuracy: 'GPS ±5 m',
          battery: 63,
        ),
      ),
    );
    expect(find.text('GPS ±5 m'), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
    expect(find.text('71%'), findsNothing);
  });

  testWidgets('a live SOS hides tools that are not built, keeps Cancel', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      SosActiveScreen(
        view: SosView(
          delivery: const SosDelivery(total: 2, delivered: 0),
          position: real(),
          battery: 63,
          toolsAvailable: false,
        ),
      ),
    );
    expect(find.text('Siren'), findsNothing);
    expect(find.text('Torch strobe'), findsNothing);
    expect(find.textContaining('Call 112'), findsNothing);
    expect(find.textContaining('Cancel SOS'), findsOneWidget);
  });

  testWidgets('the design sample still shows the tools', (tester) async {
    await pumpPhone(tester, const SosActiveScreen(view: SosView()));
    expect(find.text('Siren'), findsOneWidget);
    expect(find.textContaining('Call 112'), findsOneWidget);
  });

  testWidgets('the fall screen shows the detail it is given', (tester) async {
    await pumpPhone(
      tester,
      const FallCountdownScreen(view: FallView(detail: 'A fall was suspected')),
    );
    expect(find.text('A fall was suspected'), findsOneWidget);
    expect(find.textContaining('hard impact'), findsNothing);
  });
}

void lostTests() {
  testWidgets('a live lost screen invents no distances or group claims', (
    tester,
  ) async {
    await pumpPhone(
      tester,
      const LostModeScreen(
        view: LostView(live: true, accuracy: 'GPS ±5 m', battery: 63),
      ),
    );
    expect(find.text('Stay where you are'), findsOneWidget);
    expect(find.textContaining('320', findRichText: true), findsNothing);
    expect(find.textContaining('seen 4 min ago'), findsNothing);
    expect(find.textContaining('Your group is coming'), findsNothing);
    expect(find.textContaining('Group'), findsNothing);
    expect(find.text('I need to move'), findsNothing);
    expect(find.text('GPS ±5 m'), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
    expect(find.textContaining('I’m found'), findsOneWidget);
  });

  testWidgets('the design sample lost screen is unchanged', (tester) async {
    await pumpPhone(tester, const LostModeScreen(view: LostView()));
    expect(find.textContaining('320', findRichText: true), findsOneWidget);
    expect(find.text('I need to move'), findsOneWidget);
  });
}
