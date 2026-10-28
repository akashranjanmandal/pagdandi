import 'dart:io';

import 'package:engine_navigation/engine_navigation.dart';
import 'package:flutter/widgets.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/models/route_summary.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:pagdandi_app/screens/basecamp_screen.dart';
import 'package:pagdandi_app/screens/contacts_screen.dart';
import 'package:pagdandi_app/screens/emergency_card_screen.dart';
import 'package:pagdandi_app/screens/setup_screen.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

import 'golden_harness.dart';

Readiness readiness({
  int contacts = 2,
  bool sms = true,
  bool running = false,
  bool card = true,
}) => Readiness(
  contactCount: contacts,
  location: true,
  sms: sms,
  notifications: true,
  backgroundLocation: false,
  cardFilled: card,
  trekRunning: running,
);

SetupScreen setup({int contacts = 1}) => SetupScreen(
  contacts: [for (var i = 0; i < contacts; i++) '+91 98765 4321$i'],
  name: 'Akash',
  leftHanded: false,
  readiness: readiness(),
  onHand: (_) {},
  onName: (_) {},
  onAddContact: (_) async => true,
  onRemoveContact: (_) {},
  onRequest: (_) async => false,
  onOpenSettings: () {},
  onFinish: () {},
);

RouteSummary brahmatalSummary() => RouteSummary.of(
  parseGpx(
    File('assets/routes/lohajung_brahmatal.gpx').readAsStringSync(),
    id: 'lohajung-brahmatal',
  ),
  day: DateTime.utc(2026, 12, 14),
  utcOffset: const Duration(hours: 5, minutes: 30),
);

void main() {
  Future<void> shot(
    WidgetTester tester,
    Widget screen,
    String name, {
    UiPrefs prefs = const UiPrefs(reduceMotion: true),
    double textScale = 1,
  }) async {
    await pumpPhone(tester, screen, prefs: prefs, textScale: textScale);
    await expectLater(
      find.byType(UiScope),
      matchesGoldenFile('m1/$name.png'),
    );
  }

  group('Basecamp', () {
    testWidgets(
      'ready',
      (t) => shot(t, BasecampScreen(readiness: readiness()), 'basecamp_ready'),
    );
    testWidgets(
      'blocked',
      (t) => shot(
        t,
        BasecampScreen(
          readiness: readiness(contacts: 0, sms: false, card: false),
        ),
        'basecamp_blocked',
      ),
    );
    testWidgets(
      'running',
      (t) => shot(
        t,
        BasecampScreen(readiness: readiness(running: true)),
        'basecamp_running',
      ),
    );
    testWidgets(
      'text 1.5',
      (t) => shot(
        t,
        BasecampScreen(readiness: readiness(contacts: 0, sms: false)),
        'basecamp_text_1_5',
        textScale: 1.5,
      ),
    );
    testWidgets(
      'sunlight',
      (t) => shot(
        t,
        BasecampScreen(readiness: readiness(contacts: 0)),
        'basecamp_sunlight',
        prefs: const UiPrefs(sunlight: true, reduceMotion: true),
      ),
    );
  });

  group('Basecamp with a route', () {
    testWidgets(
      'brahmatal',
      (t) => shot(
        t,
        BasecampScreen(
          readiness: readiness(),
          routes: const [
            RouteInfo(
              'lohajung-brahmatal',
              'Lohajung to Brahmatal',
              'assets/routes/lohajung_brahmatal.gpx',
            ),
          ],
          selectedRouteId: 'lohajung-brahmatal',
          summary: brahmatalSummary(),
        ),
        'basecamp_brahmatal',
      ),
    );
  });

  group('Setup', () {
    testWidgets('first step', (t) => shot(t, setup(), 'setup_hand'));
    testWidgets(
      'text 1.5',
      (t) => shot(t, setup(), 'setup_text_1_5', textScale: 1.5),
    );
  });

  group('Emergency card', () {
    testWidgets(
      'view',
      (t) => shot(
        t,
        const EmergencyCardScreen(
          card: EmergencyCard(
            bloodGroup: 'B+',
            allergies: 'Penicillin',
            medicines: 'Diamox 125 mg',
          ),
          contacts: ['+91 98765 43210'],
        ),
        'card_view',
      ),
    );
    testWidgets(
      'empty',
      (t) => shot(
        t,
        const EmergencyCardScreen(card: EmergencyCard(), contacts: []),
        'card_empty',
      ),
    );
  });

  group('Contacts', () {
    testWidgets(
      'two saved',
      (t) => shot(
        t,
        ContactsScreen(
          contacts: const ['+91 98765 43210', '+91 98765 43211'],
          onAdd: (_) async => true,
          onRemove: (_) {},
        ),
        'contacts',
      ),
    );
  });
}
