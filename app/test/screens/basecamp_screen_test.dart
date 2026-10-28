import 'package:engine_navigation/engine_navigation.dart'
    show Route, RoutePoint, Waypoint;
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/models/route_summary.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:pagdandi_app/screens/basecamp_screen.dart';

import '../goldens/golden_harness.dart';

Readiness ready({
  int contacts = 2,
  bool sms = true,
  bool running = false,
  bool card = true,
}) => Readiness(
  contactCount: contacts,
  location: true,
  sms: sms,
  notifications: true,
  backgroundLocation: true,
  cardFilled: card,
  trekRunning: running,
);

void main() {
  testWidgets('ready: Start trek is pressable and says nothing is wrong', (
    tester,
  ) async {
    var started = 0;
    await pumpPhone(
      tester,
      BasecampScreen(readiness: ready(), onStart: () => started++),
    );
    expect(find.textContaining('Fix'), findsNothing);
    await tester.tap(find.text('Start trek'));
    expect(started, 1);
  });

  testWidgets('blocked: Start is disabled, explains why, and never fires', (
    tester,
  ) async {
    var started = 0;
    await pumpPhone(
      tester,
      BasecampScreen(
        readiness: ready(contacts: 0, sms: false),
        onStart: () => started++,
      ),
    );
    expect(find.text('Fix 2 things first'), findsOneWidget);
    await tester.tap(find.text('Start trek'));
    expect(started, 0);
  });

  testWidgets('each missing item offers its own fix', (tester) async {
    final fixed = <ReadyItem>[];
    await pumpPhone(
      tester,
      BasecampScreen(
        readiness: ready(contacts: 0, sms: false),
        onFix: fixed.add,
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.tap(find.text('Allow'));
    expect(fixed, [ReadyItem.contacts, ReadyItem.sms]);
  });

  testWidgets('items that are fine have no fix button', (tester) async {
    await pumpPhone(tester, BasecampScreen(readiness: ready()));
    expect(find.text('Add'), findsNothing);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('a running trek shows Open trek instead of Start trek', (
    tester,
  ) async {
    var opened = 0;
    await pumpPhone(
      tester,
      BasecampScreen(
        readiness: ready(running: true),
        onOpenTrek: () => opened++,
      ),
    );
    expect(find.text('Start trek'), findsNothing);
    await tester.tap(find.text('Open trek'));
    expect(opened, 1);
  });

  testWidgets('the Emergency card key is reachable before the trek', (
    tester,
  ) async {
    var opened = 0;
    await pumpPhone(
      tester,
      BasecampScreen(readiness: ready(), onEmergencyCard: () => opened++),
    );
    await tester.tap(find.text('Emergency card').last);
    expect(opened, 1);
  });

  testWidgets('every row is one semantic node with its state in words', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPhone(tester, BasecampScreen(readiness: ready(contacts: 0)));
    expect(
      find.bySemanticsLabel('Emergency contacts: none added'),
      findsOneWidget,
    );
    handle.dispose();
  });

  group('route choice', () {
    const options = [
      RouteInfo('lohajung-brahmatal', 'Lohajung to Brahmatal', 'x'),
    ];
    final summary = RouteSummary.of(
      Route(
        id: 'r',
        name: 'Lohajung-Brahmatal',
        points: [
          for (var i = 0; i <= 100; i++)
            RoutePoint(30.13 + i * 0.0005, 79.6, ele: 2373.0 + i * 8.4),
        ],
        waypoints: const [Waypoint('Brahm Tal (Brahmatal)', 30.18, 79.6)],
        attribution: 'OpenStreetMap contributors',
      ),
      day: DateTime.utc(2026, 12, 14),
      utcOffset: const Duration(hours: 5, minutes: 30),
    );

    testWidgets('free trek and each route are offered, free trek chosen', (
      tester,
    ) async {
      await pumpPhone(
        tester,
        BasecampScreen(readiness: ready(), routes: options),
      );
      expect(find.text('Free trek'), findsOneWidget);
      expect(find.text('Lohajung to Brahmatal'), findsOneWidget);
    });

    testWidgets(
      'choosing a route reports it, choosing free trek reports null',
      (
        tester,
      ) async {
        final chosen = <String?>[];
        await pumpPhone(
          tester,
          BasecampScreen(
            readiness: ready(),
            routes: options,
            selectedRouteId: 'lohajung-brahmatal',
            onSelectRoute: chosen.add,
          ),
        );
        await tester.tap(find.text('Free trek'));
        await tester.tap(find.text('Lohajung to Brahmatal'));
        expect(chosen, [null, 'lohajung-brahmatal']);
      },
    );

    testWidgets('the chosen route is summarised with its sources', (
      tester,
    ) async {
      await pumpPhone(
        tester,
        BasecampScreen(
          readiness: ready(),
          routes: options,
          selectedRouteId: 'lohajung-brahmatal',
          summary: summary,
        ),
      );
      expect(find.textContaining('5.6 km'), findsWidgets);
      expect(find.textContaining('+840 m climb'), findsOneWidget);
      expect(find.textContaining('Brahm Tal (Brahmatal)'), findsOneWidget);
      expect(find.textContaining('Sunset'), findsOneWidget);
      expect(find.textContaining('turn back'), findsWidgets);
      expect(find.textContaining('snow and ice'), findsOneWidget);
      expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    });

    testWidgets('without routes there is no route section at all', (
      tester,
    ) async {
      await pumpPhone(tester, BasecampScreen(readiness: ready()));
      expect(find.text('Free trek'), findsNothing);
    });

    testWidgets('a running trek shows no route chooser', (tester) async {
      await pumpPhone(
        tester,
        BasecampScreen(
          readiness: ready(running: true),
          routes: options,
        ),
      );
      expect(find.text('Free trek'), findsNothing);
    });
  });
}
