import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';
import 'package:pagdandi_app/screens/setup_screen.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

import '../goldens/golden_harness.dart';

class _Probe {
  final requested = <AppPermission>[];
  final names = <String>[];
  final added = <String>[];
  final removed = <String>[];
  final hands = <bool>[];
  int settings = 0;
  int finished = 0;
  final grant = <AppPermission>{};
  List<String> contacts = <String>[];
  String name = '';

  int initialStep = 0;
  final steps = <int>[];

  List<String> guide = const ['Open Settings', 'Choose Unrestricted'];

  Widget screen() => SetupScreen(
    batteryGuide: guide,
    initialStep: initialStep,
    onStep: steps.add,
    contacts: contacts,
    name: name,
    leftHanded: false,
    readiness: Readiness(
      contactCount: contacts.length,
      location: grant.contains(AppPermission.location),
      sms: grant.contains(AppPermission.sms),
      notifications: grant.contains(AppPermission.notifications),
      backgroundLocation: grant.contains(AppPermission.backgroundLocation),
      cardFilled: false,
      trekRunning: false,
    ),
    onHand: hands.add,
    onName: names.add,
    onAddContact: (n) async {
      added.add(n);
      return n.startsWith('+');
    },
    onRemoveContact: removed.add,
    onRequest: (p) async {
      requested.add(p);
      return grant.contains(p);
    },
    onOpenSettings: () => settings++,
    onFinish: () => finished++,
  );
}

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  guideTests();
  backTests();
  stepTests();
  testWidgets('starts with the hand question and a progress count', (
    tester,
  ) async {
    final probe = _Probe();
    await pumpPhone(tester, probe.screen());
    expect(find.text('Which hand holds your phone?'), findsOneWidget);
    expect(find.text('1 of 9'), findsOneWidget);
  });

  testWidgets('choosing left hand is reported', (tester) async {
    final probe = _Probe();
    await pumpPhone(tester, probe.screen());
    await tester.tap(find.text('Left'));
    expect(probe.hands, [true]);
  });

  testWidgets('the name step cannot continue without a name', (tester) async {
    final probe = _Probe();
    await pumpPhone(tester, probe.screen());
    await next(tester);
    expect(find.text('What should your group call you?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('What should your group call you?'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Akash');
    expect(probe.names.last, 'Akash');
  });

  testWidgets('back returns to the previous step', (tester) async {
    final probe = _Probe()..name = 'Akash';
    await pumpPhone(tester, probe.screen());
    await next(tester);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Which hand holds your phone?'), findsOneWidget);
  });

  testWidgets('contacts need at least one, and a bad number is explained', (
    tester,
  ) async {
    final probe = _Probe()..name = 'Akash';
    await pumpPhone(tester, probe.screen());
    await next(tester);
    await next(tester);
    expect(find.text('Emergency contacts'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Emergency contacts'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '98765');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(
      find.text('Enter a phone number with country code, like +91…'),
      findsOneWidget,
    );
  });

  testWidgets('a permission step asks, and a refusal never dead-ends', (
    tester,
  ) async {
    final probe = _Probe()
      ..name = 'Akash'
      ..contacts = ['+911111111111'];
    await pumpPhone(tester, probe.screen());
    await next(tester);
    await next(tester);
    await next(tester);
    expect(find.text('Allow location'), findsWidgets);
    await tester.tap(find.text('Allow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(probe.requested, [AppPermission.location]);
    expect(find.text('Continue without it'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    expect(probe.settings, 1);
    await tester.tap(find.text('Continue without it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Allow location all the time'), findsWidgets);
  });

  testWidgets('every permission step carries its one-line reason', (
    tester,
  ) async {
    final probe = _Probe()
      ..name = 'Akash'
      ..contacts = ['+911111111111'];
    await pumpPhone(tester, probe.screen());
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    expect(
      find.text(
        'Your position reaches your group and your SOS without network.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the last step is honest about what is unconfirmed', (
    tester,
  ) async {
    final probe = _Probe()
      ..name = 'Akash'
      ..contacts = ['+911111111111'];
    await pumpPhone(tester, probe.screen());
    await next(tester); // hand → name
    await next(tester); // name → contacts
    await next(tester); // contacts → location
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Skip').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('You are ready'), findsOneWidget);
    expect(find.text('Send SMS'), findsOneWidget);
    expect(find.text('not allowed'), findsWidgets);
    await tester.tap(find.text('Finish'));
    expect(probe.finished, 1);
  });
}

void guideTests() {
  testWidgets('the keep-running step lists the brand steps, numbered', (
    tester,
  ) async {
    final probe = _Probe()
      ..name = 'Akash'
      ..initialStep = 7;
    await pumpPhone(tester, probe.screen());
    expect(find.text('Keep Pagdandi running'), findsOneWidget);
    expect(find.text('1. Open Settings'), findsOneWidget);
    expect(find.text('2. Choose Unrestricted'), findsOneWidget);
  });
}

void stepTests() {
  testWidgets('resumes at the saved step', (tester) async {
    final probe = _Probe()
      ..name = 'Akash'
      ..initialStep = 2
      ..contacts = ['+911111111111'];
    await pumpPhone(tester, probe.screen());
    expect(find.text('Emergency contacts'), findsOneWidget);
    expect(find.text('3 of 9'), findsOneWidget);
  });

  testWidgets('reports each step so it can be saved', (tester) async {
    final probe = _Probe()..name = 'Akash';
    await pumpPhone(tester, probe.screen());
    await next(tester);
    expect(probe.steps, [1]);
  });

  testWidgets('a saved step beyond the end is kept inside the range', (
    tester,
  ) async {
    final probe = _Probe()..initialStep = 99;
    await pumpPhone(tester, probe.screen());
    expect(find.text('You are ready'), findsOneWidget);
  });
}

void backTests() {
  Future<void> pumpWithNavigator(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    // WidgetsApp is what routes the system Back button to the Navigator.
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        pageRouteBuilder: <T>(route, builder) => PageRouteBuilder<T>(
          settings: route,
          pageBuilder: (context, _, _) => builder(context),
        ),
        builder: (context, child) =>
            UiScope(prefs: const UiPrefs(reduceMotion: true), child: child!),
        home: screen,
      ),
    );
    await tester.pump();
  }

  testWidgets('system Back on a later step goes to the previous step', (
    tester,
  ) async {
    final probe = _Probe()..name = 'Akash';
    await pumpWithNavigator(tester, probe.screen());
    await next(tester);
    expect(find.text('What should your group call you?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Which hand holds your phone?'), findsOneWidget);
  });

  testWidgets('system Back on the first step is left to the system', (
    tester,
  ) async {
    final probe = _Probe();
    await pumpWithNavigator(tester, probe.screen());
    // Nothing to go back to: the pop is not swallowed.
    final handled = await tester.binding.handlePopRoute();
    expect(handled, isFalse);
  });
}
