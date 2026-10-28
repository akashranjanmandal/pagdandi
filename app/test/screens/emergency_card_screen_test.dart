import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/screens/emergency_card_screen.dart';

import '../goldens/golden_harness.dart';

void main() {
  const filled = EmergencyCard(
    bloodGroup: 'B+',
    allergies: 'Penicillin',
    medicines: 'Diamox',
  );

  testWidgets('shows blood group first and the rest plainly', (tester) async {
    await pumpPhone(
      tester,
      const EmergencyCardScreen(card: filled, contacts: ['+911111111111']),
    );
    expect(find.text('B+'), findsOneWidget);
    expect(find.text('Penicillin'), findsOneWidget);
    expect(find.text('Diamox'), findsOneWidget);
    expect(find.text('+911111111111'), findsOneWidget);
  });

  testWidgets('empty fields say so instead of leaving a gap', (tester) async {
    await pumpPhone(
      tester,
      const EmergencyCardScreen(card: EmergencyCard(), contacts: []),
    );
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('None entered'), findsNWidgets(2));
    expect(find.text('No contacts yet'), findsOneWidget);
  });

  testWidgets('edit, change and save sends the new card', (tester) async {
    EmergencyCard? saved;
    await pumpPhone(
      tester,
      EmergencyCardScreen(
        card: filled,
        contacts: const [],
        onSave: (c) => saved = c,
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pump();
    final fields = find.byType(EditableText);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.first, 'O-');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(saved?.bloodGroup, 'O-');
    expect(saved?.allergies, 'Penicillin');
    expect(find.text('Edit'), findsOneWidget, reason: 'back to view mode');
  });

  testWidgets('cancel discards edits', (tester) async {
    EmergencyCard? saved;
    await pumpPhone(
      tester,
      EmergencyCardScreen(
        card: filled,
        contacts: const [],
        onSave: (c) => saved = c,
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, 'AB+');
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(saved, isNull);
    expect(find.text('B+'), findsOneWidget);
  });

  testWidgets('lock-screen view is read-only with no edit key', (tester) async {
    await pumpPhone(
      tester,
      const EmergencyCardScreen(
        card: filled,
        contacts: [],
        readOnly: true,
      ),
    );
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Unlock to edit'), findsOneWidget);
  });

  testWidgets(
    'Call keys appear only when calling is wired, named per contact',
    (
      tester,
    ) async {
      final called = <String>[];
      final handle = tester.ensureSemantics();
      await pumpPhone(
        tester,
        EmergencyCardScreen(
          card: filled,
          contacts: const ['+911111111111'],
          onCall: called.add,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Call +911111111111'));
      expect(called, ['+911111111111']);
      handle.dispose();
    },
  );

  testWidgets('back is reported', (tester) async {
    var back = 0;
    await pumpPhone(
      tester,
      EmergencyCardScreen(
        card: filled,
        contacts: const [],
        onBack: () => back++,
      ),
    );
    await tester.tap(find.text('Back'));
    expect(back, 1);
  });
}
