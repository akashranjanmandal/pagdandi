// Runs the REAL app on a device or emulator: real native bridge, real
// foreground service, real headless core. Before running, grant the
// permissions with `tool/qa/grant_permissions.sh` (system dialogs cannot be
// tapped from a Flutter test).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pagdandi_app/app.dart';
import 'package:pagdandi_app/app/services.dart';
// The headless core's entry point must be part of the program so the
// foreground service can launch it (lib/main.dart does the same).
// ignore: unused_import
import 'package:pagdandi_app/core/trek_core_main.dart';

Future<void> settle(WidgetTester tester, [int ms = 600]) async {
  await tester.pump(Duration(milliseconds: ms));
  await tester.pump(Duration(milliseconds: ms));
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 40,
}) async {
  for (var i = 0; i < seconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('never saw ${finder.describeMatch(Plurality.one)}');
}

/// Waits until [finder] matches exactly [count] widgets (a crossfade between
/// two Setup steps keeps both in the tree for a moment).
Future<void> waitForCount(
  WidgetTester tester,
  Finder finder,
  int count, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().length == count) return;
  }
  fail('expected $count of ${finder.describeMatch(Plurality.many)}');
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run to a live trek and an SOS, on the real phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: PagdandiApp(bootstrap: bootstrapServices)),
    );
    await waitFor(tester, find.text('Which hand holds your phone?'));

    // Setup.
    await tapText(tester, 'Continue');
    await waitFor(tester, find.text('What should your group call you?'));
    await waitForCount(tester, find.byType(EditableText), 1);
    await tester.enterText(find.byType(EditableText), 'Akash');
    await settle(tester);
    await tapText(tester, 'Continue');
    await waitFor(tester, find.text('Emergency contacts'));
    await waitForCount(tester, find.byType(EditableText), 1);
    await tester.enterText(find.byType(EditableText), '+15555215556');
    await settle(tester);
    await tapText(tester, 'Add');
    await waitFor(tester, find.text('+15555215556'));
    await tapText(tester, 'Continue');

    // Permissions were granted by the script, so each step says Allowed.
    for (final title in [
      'Allow location',
      'Allow location all the time',
      'Allow sending SMS',
      'Allow notifications',
    ]) {
      await waitFor(tester, find.text(title));
      await waitForCount(tester, find.text('Allowed'), 1);
      await tapText(tester, 'Continue');
    }
    await waitFor(tester, find.text('Keep Pagdandi running'));
    await tapText(tester, 'Skip');
    await waitFor(tester, find.text('You are ready'));
    await tapText(tester, 'Finish');

    // Basecamp.
    await waitFor(tester, find.text('Ready to trek?'));
    expect(find.textContaining('Fix'), findsNothing);
    // Choose the Brahmatal route (the walker script feeds GPS along it).
    await tapText(tester, 'Lohajung to Brahmatal');
    await waitFor(tester, find.textContaining('+1,426 m climb'));
    await waitFor(tester, find.textContaining('Sunset'));
    await tapText(tester, 'Start trek');

    // The trek screen only appears when the headless core is running and has
    // published its state through the native relay.
    await waitFor(tester, find.text('End trek · hold 3 s'), seconds: 90);
    expect(find.text('SOS'), findsOneWidget);

    // Real guidance from the walker script: on the trail, then off, then back.
    await waitFor(tester, find.textContaining('to Bhengal Tal'), seconds: 120);
    await waitFor(tester, find.textContaining('m off trail'), seconds: 120);
    await waitFor(tester, find.textContaining('I know, exploring'), seconds: 5);
    await waitFor(tester, find.textContaining('to Bhengal Tal'), seconds: 120);

    // Hold SOS for 3 seconds.
    final g = await tester.startGesture(tester.getCenter(find.text('SOS')));
    await tester.pump();
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await g.up();
    await waitFor(tester, find.textContaining('SOS'), seconds: 30);
    await waitFor(tester, find.textContaining('Cancel SOS'), seconds: 60);
    expect(find.text('SMS to 1 contact'), findsOneWidget);
    expect(
      find.textContaining('27.0410'),
      findsNothing,
      reason: 'no sample coordinates on a real SOS',
    );

    // Cancel it with a 5 second hold.
    final c = await tester.startGesture(
      tester.getCenter(find.textContaining('Cancel SOS')),
    );
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await c.up();
    await waitFor(tester, find.text('End trek · hold 3 s'), seconds: 60);

    // End the trek.
    final e = await tester.startGesture(
      tester.getCenter(find.text('End trek · hold 3 s')),
    );
    await tester.pump();
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await e.up();
    await waitFor(tester, find.text('Ready to trek?'), seconds: 60);
  });
}
