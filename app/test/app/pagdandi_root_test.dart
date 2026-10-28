import 'dart:async';

import 'package:core_db/core_db.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:engine_navigation/engine_navigation.dart' show NavStatus;
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/app/pagdandi_root.dart';
import 'package:pagdandi_app/client/core_client.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:testing/testing.dart';
import 'package:trek_core/trek_core.dart';

import '../goldens/golden_harness.dart';

class _Perms implements PermissionService {
  @override
  Future<bool> isPermanentlyDenied(AppPermission p) async => false;
  final have = <AppPermission>{};
  @override
  Future<Set<AppPermission>> granted() async => {...have};
  @override
  Future<bool> request(AppPermission p) async => have.contains(p);
  @override
  Future<void> openSettings() async {}
}

class _Ui implements UiChannel {
  final controller = StreamController<String>.broadcast(sync: true);
  final sent = <String>[];
  @override
  Stream<String> get states => controller.stream;
  @override
  Future<void> send(String json) async => sent.add(json);
}

String stateJson(
  Activity a, {
  Emergency e = const NoEmergency(),
  SosSummary sos = const SosSummary.none(),
  NavView? nav,
}) => CoreStateMessage(
  state: TrekState(activity: a, emergency: e, mapOpen: false),
  sos: sos,
  issues: const [],
  stats: const TrekStats(
    distanceM: 1200,
    climbM: 10,
    elapsed: Duration(minutes: 20),
    altitudeM: null,
  ),
  battery: 90,
  fix: null,
  at: DateTime.utc(2026, 10, 28),
  nav: nav,
).encode();

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PagdandiDatabase db;
  late _Perms perms;
  late _Ui ui;
  late CoreClient client;
  late AppController app;
  late FakeSirenOutput siren;
  late FakeDialer dialer;
  late FakeSignalMonitor signal;

  Future<void> boot(WidgetTester tester, {bool setupDone = true}) async {
    await tester.runAsync(() async {
      db = PagdandiDatabase(NativeDatabase.memory());
      final settings = SettingsRepository(db);
      if (setupDone) await settings.set('setup_done', 'true');
      perms = _Perms();
      ui = _Ui();
      client = CoreClient(channel: ui, register: () async {});
      app = AppController(
        client: client,
        settings: settings,
        permissions: perms,
        service: FakeTrekService(),
        routes: const AssetRouteLibrary(),
        siren: siren = FakeSirenOutput(),
        torch: FakeTorchOutput(),
        dialer: dialer = FakeDialer(),
        signal: signal = FakeSignalMonitor(),
      );
      await client.connect();
      await app.load();
    });
    await pumpPhone(
      tester,
      PagdandiRoot(app: app, client: client, leftHanded: false, onHand: (_) {}),
    );
  }

  testWidgets('a first run opens Setup', (tester) async {
    await boot(tester, setupDone: false);
    expect(find.text('Which hand holds your phone?'), findsOneWidget);
  });

  testWidgets('after setup the app opens at Basecamp', (tester) async {
    await boot(tester);
    expect(find.text('Ready to trek?'), findsOneWidget);
    expect(find.text('Fix 2 things first'), findsNothing);
    expect(find.textContaining('Fix'), findsWidgets);
  });

  testWidgets('a running trek shows the live trek screen', (tester) async {
    await boot(tester);
    ui.controller.add(stateJson(Activity.moving));
    await tester.pump();
    expect(find.text('Tracking'), findsNothing, reason: 'no fix: GPS lost tag');
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('End trek · hold 3 s'), findsOneWidget);
  });

  testWidgets('SOS held 3 seconds on the trek screen sends SosPressed', (
    tester,
  ) async {
    await boot(tester);
    ui.controller.add(stateJson(Activity.moving));
    await tester.pump();
    final g = await tester.startGesture(tester.getCenter(find.text('SOS')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3100));
    await g.up();
    expect(ui.sent.map(decodeCommand), [isA<SosPressed>()]);
  });

  testWidgets('the core saying SOS takes over the whole screen', (
    tester,
  ) async {
    await boot(tester);
    ui.controller.add(
      stateJson(
        Activity.moving,
        e: const SosActive(),
        sos: const SosSummary(
          active: true,
          total: 2,
          queued: 1,
          sending: 0,
          sent: 0,
          delivered: 1,
          failed: 0,
          cancelled: 0,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('SOS delivered to 1 of 2'), findsOneWidget);
    expect(find.text('End trek · hold 3 s'), findsNothing);
  });

  testWidgets('the SOS siren toggle really switches the siren', (tester) async {
    await boot(tester);
    ui.controller.add(stateJson(Activity.moving, e: const SosActive()));
    await tester.pump();
    await tester.tap(find.text('Siren'));
    await tester.pump();
    expect(siren.isOn, isTrue);
    await tester.tap(find.text('Siren'));
    await tester.pump();
    expect(siren.isOn, isFalse);
  });

  testWidgets('Call 112 is off without signal and opens the dialer with it', (
    tester,
  ) async {
    await boot(tester);
    ui.controller.add(stateJson(Activity.moving, e: const SosActive()));
    await tester.pump();
    await tester.tap(find.textContaining('Call 112'));
    expect(dialer.opened, isEmpty, reason: 'no signal yet');
    signal.set(SignalState.inService);
    await tester.pump();
    await tester.tap(find.textContaining('Call 112'));
    expect(dialer.opened, ['112']);
  });

  testWidgets('lost mode in the real app shows no sample distances', (
    tester,
  ) async {
    await boot(tester);
    ui.controller.add(stateJson(Activity.moving, e: const LostMode()));
    await tester.pump();
    expect(find.text('Stay where you are'), findsOneWidget);
    expect(find.textContaining('320', findRichText: true), findsNothing);
    expect(find.textContaining('seen 4 min ago'), findsNothing);
  });

  testWidgets(
    'off route shows a working snooze key, wrong way a heading-back key',
    (tester) async {
      await boot(tester);
      await tester.runAsync(() => app.selectRoute('lohajung-brahmatal'));
      ui.controller.add(
        stateJson(
          Activity.moving,
          nav: _nav(NavStatus.offRoute),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('I know, exploring'));
      expect(ui.sent.map(decodeNavCommand), [NavCommand.snoozeAlerts]);

      ui.controller.add(
        stateJson(Activity.moving, nav: _nav(NavStatus.wrongWay)),
      );
      await tester.pump();
      await tester.tap(find.text('I’m heading back'));
      expect(ui.sent.map(decodeNavCommand).last, NavCommand.reverseRoute);
    },
  );

  testWidgets('a snoozed off-route screen counts down and can resume', (
    tester,
  ) async {
    await boot(tester);
    await tester.runAsync(() => app.selectRoute('lohajung-brahmatal'));
    ui.controller.add(
      stateJson(
        Activity.moving,
        nav: _nav(
          NavStatus.offRoute,
          snoozedUntil: DateTime.utc(2026, 10, 28, 0, 10),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Snoozed 10:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.textContaining('Snoozed 9:57'), findsOneWidget);
    await tester.tap(find.textContaining('Snoozed'));
    expect(ui.sent.map(decodeNavCommand).last, NavCommand.resumeAlerts);
  });

  testWidgets('the fall countdown ticks every second', (tester) async {
    await boot(tester);
    ui.controller.add(
      stateJson(
        Activity.moving,
        e: FallCountdown(DateTime.utc(2026, 10, 28, 0, 1)),
      ),
    );
    await tester.pump();
    expect(find.text('60'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('57'), findsOneWidget);
  });

  testWidgets('coming back from system settings refreshes the permissions', (
    tester,
  ) async {
    await boot(tester);
    expect(find.text('Fix 3 things first'), findsOneWidget);
    perms.have.addAll([AppPermission.location, AppPermission.sms]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Fix 1 thing first'), findsOneWidget);
  });

  testWidgets('the Emergency card has a Call key per contact that dials', (
    tester,
  ) async {
    await boot(tester);
    await tester.runAsync(() => app.addContact('+911111111111'));
    await tester.pump();
    await tester.tap(find.text('Emergency card').last);
    await tester.pump();
    final handle = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('Call +911111111111'));
    expect(dialer.opened, ['+911111111111']);
    handle.dispose();
  });

  testWidgets('the Emergency card opens from Basecamp and goes back', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(find.text('Emergency card').last);
    await tester.pump();
    expect(find.text('Blood group'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.text('Ready to trek?'), findsOneWidget);
  });
}

NavView _nav(NavStatus status, {DateTime? snoozedUntil}) => NavView(
  routeId: 'lohajung-brahmatal',
  routeName: 'Lohajung-Brahmatal',
  status: status,
  progressM: 4000,
  remainingM: 6700,
  totalM: 10700,
  crossTrackM: 50,
  bearingToGoDeg: 20,
  arrived: false,
  reversed: false,
  climbLeftM: 700,
  snoozedUntil: snoozedUntil,
);
