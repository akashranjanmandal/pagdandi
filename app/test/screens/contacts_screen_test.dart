import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/screens/contacts_screen.dart';

import '../goldens/golden_harness.dart';

void main() {
  testWidgets('lists contacts and removes one', (tester) async {
    final removed = <String>[];
    await pumpPhone(
      tester,
      ContactsScreen(
        contacts: const ['+911111111111', '+912222222222'],
        onAdd: (_) async => true,
        onRemove: removed.add,
      ),
    );
    expect(find.text('+911111111111'), findsOneWidget);
    final handle = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('Remove +912222222222'));
    expect(removed, ['+912222222222']);
    handle.dispose();
  });

  testWidgets('adds a number and explains a bad one', (tester) async {
    final added = <String>[];
    await pumpPhone(
      tester,
      ContactsScreen(
        contacts: const [],
        onAdd: (n) async {
          added.add(n);
          return n.startsWith('+');
        },
        onRemove: (_) {},
      ),
    );
    await tester.enterText(find.byType(EditableText), '123');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(
      find.text('Enter a phone number with country code, like +91…'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(EditableText), '+911234567890');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(added, ['123', '+911234567890']);
    expect(
      find.text('Enter a phone number with country code, like +91…'),
      findsNothing,
    );
  });

  testWidgets('warns plainly when there are none', (tester) async {
    await pumpPhone(
      tester,
      ContactsScreen(
        contacts: const [],
        onAdd: (_) async => true,
        onRemove: (_) {},
      ),
    );
    expect(find.text('An SOS has nobody to message yet.'), findsOneWidget);
  });

  testWidgets('Done goes back', (tester) async {
    var done = 0;
    await pumpPhone(
      tester,
      ContactsScreen(
        contacts: const ['+911111111111'],
        onAdd: (_) async => true,
        onRemove: (_) {},
        onDone: () => done++,
      ),
    );
    await tester.tap(find.text('Done'));
    expect(done, 1);
  });
}
