import 'dart:async';

import 'package:core_db/core_db.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/client/core_client.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:testing/testing.dart';
import 'package:trek_core/trek_core.dart';

class _Perms implements PermissionService {
  final have = <AppPermission>{};
  final allow = <AppPermission>{};
  bool settingsOpened = false;
  final permanent = <AppPermission>{};
  int asked = 0;
  @override
  Future<bool> isPermanentlyDenied(AppPermission p) async =>
      permanent.contains(p);
  @override
  Future<Set<AppPermission>> granted() async => {...have};
  @override
  Future<bool> request(AppPermission p) async {
    asked++;
    if (allow.contains(p)) have.add(p);
    return have.contains(p);
  }

  @override
  Future<void> openSettings() async => settingsOpened = true;
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
}) => CoreStateMessage(
  state: TrekState(
    activity: a,
    emergency: e,
    mapOpen: false,
  ),
  sos: const SosSummary.none(),
  issues: const [],
  stats: const TrekStats(
    distanceM: 0,
    climbM: 0,
    elapsed: Duration.zero,
    altitudeM: null,
  ),
  battery: 90,
  fix: null,
  at: DateTime.utc(2026, 10, 28),
).encode();

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late PagdandiDatabase db;
  late SettingsRepository settings;
  late _Perms perms;
  late _Ui ui;
  late CoreClient client;
  late FakeTrekService service;
  late AppController app;
  late FakeSirenOutput siren;
  late FakeTorchOutput torch;
  late FakeDialer dialer;
  late FakeSignalMonitor signal;

  setUp(() async {
    db = PagdandiDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    perms = _Perms();
    ui = _Ui();
    client = CoreClient(channel: ui, register: () async {});
    service = FakeTrekService();
    siren = FakeSirenOutput();
    torch = FakeTorchOutput();
    dialer = FakeDialer();
    signal = FakeSignalMonitor();
    app = AppController(
      client: client,
      settings: settings,
      permissions: perms,
      service: service,
      siren: siren,
      torch: torch,
      dialer: dialer,
      signal: signal,
    );
    await client.connect();
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await client.dispose();
    await db.close();
  });

  test('a first run starts at Setup', () {
    expect(app.route, AppRoute.setup);
  });

  test('finishing setup remembers it and shows Basecamp next time', () async {
    await app.finishSetup();
    expect(app.route, AppRoute.basecamp);
    final again = AppController(
      client: client,
      settings: settings,
      permissions: perms,
      service: service,
    );
    await again.load();
    expect(again.route, AppRoute.basecamp);
    again.dispose();
  });

  test(
    'contacts are saved as digits with an optional plus, no duplicates',
    () async {
      expect(await app.addContact(' +91 98765 43210 '), isTrue);
      expect(await app.addContact('+919876543210'), isFalse);
      expect(await app.addContact('abc'), isFalse);
      expect(await app.addContact('12'), isFalse);
      expect(app.contacts, ['+919876543210']);
      expect(await settings.get('emergency_contacts'), '+919876543210');
    },
  );

  test('a number without a country code is refused, never guessed', () async {
    expect(await app.addContact('9876543210'), isFalse);
    expect(app.contacts, isEmpty);
  });

  test('00 is read as + and brackets and dashes are ignored', () async {
    expect(await app.addContact('00 91 98765-43210'), isTrue);
    expect(app.contacts, ['+919876543210']);
    expect(await app.addContact('(+91) 98765 43210'), isFalse, reason: 'dup');
    expect(app.contacts, hasLength(1));
  });

  test('handedness is remembered across launches', () async {
    expect(app.leftHanded, isFalse);
    await app.setLeftHanded(left: true);
    final again = AppController(
      client: client,
      settings: settings,
      permissions: perms,
      service: service,
    );
    await again.load();
    expect(again.leftHanded, isTrue);
    again.dispose();
  });

  test(
    'the Setup step is remembered, and starts at 0 on a first run',
    () async {
      expect(app.setupStep, 0);
      await app.saveSetupStep(4);
      final again = AppController(
        client: client,
        settings: settings,
        permissions: perms,
        service: service,
      );
      await again.load();
      expect(again.setupStep, 4);
      again.dispose();
    },
  );

  test('a corrupt saved step falls back to the start', () async {
    await settings.set('setup_step', 'banana');
    await app.load();
    expect(app.setupStep, 0);
  });

  test('the battery steps follow the phone maker', () async {
    final xiaomi = AppController(
      client: client,
      settings: settings,
      permissions: perms,
      service: service,
      manufacturer: () async => 'Xiaomi',
    );
    await xiaomi.load();
    expect(xiaomi.batteryGuide.join(' '), contains('Autostart'));
    xiaomi.dispose();
  });

  test('the general steps are used when the maker cannot be read', () async {
    final broken = AppController(
      client: client,
      settings: settings,
      permissions: perms,
      service: service,
      manufacturer: () async => throw StateError('no device info'),
    );
    await broken.load();
    expect(broken.batteryGuide, isNotEmpty);
    expect(broken.batteryGuide.join(' '), contains('Unrestricted'));
    broken.dispose();
  });

  group('SOS tools', () {
    test(
      'siren and torch toggles drive the hardware and show their state',
      () async {
        await app.setSiren(on: true);
        expect(siren.isOn, isTrue);
        expect(app.sirenOn, isTrue);
        await app.setTorch(on: true);
        expect(torch.strobing, isTrue, reason: 'the SOS torch is the strobe');
        expect(app.torchOn, isTrue);
        await app.setSiren(on: false);
        await app.setTorch(on: false);
        expect([siren.isOn, torch.strobing], [false, false]);
      },
    );

    test('the tools exist only when the hardware adapters were given', () {
      final bare = AppController(
        client: client,
        settings: settings,
        permissions: perms,
        service: service,
      );
      expect(bare.toolsAvailable, isFalse);
      expect(app.toolsAvailable, isTrue);
      bare.dispose();
    });

    test('Call 112 opens the dialer, it does not place the call', () async {
      await app.callEmergency();
      expect(dialer.opened, ['112']);
    });

    test('calling a contact opens the dialer with their number', () async {
      await app.call('+919876543210');
      expect(dialer.opened, ['+919876543210']);
    });

    test('any signal, even emergency-only, allows Call 112', () async {
      expect(app.signalAvailable, isFalse);
      var notified = 0;
      app.addListener(() => notified++);
      signal.set(SignalState.emergencyOnly);
      expect(app.signalAvailable, isTrue);
      signal.set(SignalState.noService);
      expect(app.signalAvailable, isFalse);
      signal.set(SignalState.inService);
      expect(app.signalAvailable, isTrue);
      expect(notified, 3);
    });

    test('siren and torch go off by themselves when the SOS is over', () async {
      await app.finishSetup();
      ui.controller.add(stateJson(Activity.moving, e: const SosActive()));
      await app.setSiren(on: true);
      await app.setTorch(on: true);
      ui.controller.add(stateJson(Activity.moving));
      await Future<void>.delayed(Duration.zero);
      expect([siren.isOn, torch.strobing], [false, false]);
      expect([app.sirenOn, app.torchOn], [false, false]);
    });

    test('they are off when the controller goes away', () async {
      await app.setSiren(on: true);
      app.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(siren.isOn, isFalse);
      app = AppController(
        client: client,
        settings: settings,
        permissions: perms,
        service: service,
      );
    });
  });

  group('routes', () {
    AppController withRoutes() => AppController(
      client: client,
      settings: settings,
      permissions: perms,
      service: service,
      routes: const AssetRouteLibrary(),
    );

    test('the bundled routes are offered, free trek is the default', () async {
      final a = withRoutes();
      await a.load();
      expect(a.routeOptions.map((r) => r.id), ['lohajung-brahmatal']);
      expect(a.selectedRouteId, isNull);
      expect(a.selectedRoute, isNull);
      a.dispose();
    });

    test('choosing a route loads it and remembers it', () async {
      final a = withRoutes();
      await a.load();
      await a.selectRoute('lohajung-brahmatal');
      expect(a.selectedRoute!.totalM, greaterThan(10000));
      expect(await settings.get('active_route'), 'lohajung-brahmatal');
      final again = withRoutes();
      await again.load();
      expect(again.selectedRouteId, 'lohajung-brahmatal');
      expect(again.selectedRoute, isNotNull);
      a.dispose();
      again.dispose();
    });

    test(
      'the chosen route has a summary for today, none for a free trek',
      () async {
        final a = AppController(
          client: client,
          settings: settings,
          permissions: perms,
          service: service,
          routes: const AssetRouteLibrary(),
          now: () => DateTime.utc(2026, 12, 14, 3),
          utcOffset: const Duration(hours: 5, minutes: 30),
        );
        await a.load();
        expect(a.routeSummary, isNull);
        await a.selectRoute('lohajung-brahmatal');
        final sum = a.routeSummary!;
        expect(sum.lengthText, '10.8 km');
        expect(sum.sun!.sunsetText, matches(RegExp(r'^17:\d\d$')));
        expect(sum.winterNote, isNotNull);
        a.dispose();
      },
    );

    test('choosing free trek clears it', () async {
      final a = withRoutes();
      await a.load();
      await a.selectRoute('lohajung-brahmatal');
      await a.selectRoute(null);
      expect(a.selectedRoute, isNull);
      expect(await settings.get('active_route'), '');
      a.dispose();
    });

    test('an unknown saved route falls back to a free trek', () async {
      await settings.set('active_route', 'gone');
      final a = withRoutes();
      await a.load();
      expect(a.selectedRoute, isNull);
      a.dispose();
    });

    test('without a route library there are no options', () async {
      expect(app.routeOptions, isEmpty);
      await app.selectRoute('x');
      expect(app.selectedRoute, isNull);
    });

    test('snooze and resume go to the core', () async {
      await app.snoozeAlerts();
      await app.resumeAlerts();
      expect(
        ui.sent.map(decodeNavCommand),
        [NavCommand.snoozeAlerts, NavCommand.resumeAlerts],
      );
    });

    test('drop-pin goes to the core', () async {
      await app.dropPin();
      expect(isDropPinCommand(ui.sent.single), isTrue);
    });

    test('reverse-route goes to the core', () async {
      await app.reverseRoute();
      expect(isReverseRouteCommand(ui.sent.single), isTrue);
    });
  });

  test('removing a contact updates storage', () async {
    await app.addContact('+911111111111');
    await app.addContact('+912222222222');
    await app.removeContact('+911111111111');
    expect(app.contacts, ['+912222222222']);
    expect(await settings.get('emergency_contacts'), '+912222222222');
  });

  test('the name is stored for the core and the SOS text', () async {
    await app.setName('  Akash ');
    expect(app.name, 'Akash');
    expect(await settings.get('member_name'), 'Akash');
  });

  test('readiness follows permissions and contacts', () async {
    await app.finishSetup();
    expect(app.readiness.canStart, isFalse);
    perms.have.addAll([AppPermission.location, AppPermission.sms]);
    await app.addContact('+911111111111');
    await app.refreshPermissions();
    expect(app.readiness.canStart, isTrue);
  });

  test(
    'fixing a row asks for the permission and re-reads the result',
    () async {
      perms.allow.add(AppPermission.sms);
      await app.fix(ReadyItem.sms);
      expect(
        app.readiness.rows.firstWhere((r) => r.id == ReadyItem.sms).status,
        ReadyStatus.ok,
      );
    },
  );

  test(
    'a permanently denied permission goes straight to the settings',
    () async {
      perms.permanent.add(AppPermission.sms);
      await app.fix(ReadyItem.sms);
      expect(perms.settingsOpened, isTrue);
      expect(perms.asked, 0, reason: 'the system would not show a prompt');
    },
  );

  test('Setup asks the same way: settings, not a dead Allow key', () async {
    perms.permanent.add(AppPermission.location);
    expect(await app.requestPermission(AppPermission.location), isFalse);
    expect(perms.settingsOpened, isTrue);
    expect(perms.asked, 0);
  });

  test('a refused permission offers the system settings', () async {
    await app.fix(ReadyItem.sms);
    expect(app.lastRefused, ReadyItem.sms);
    await app.openSettings();
    expect(perms.settingsOpened, isTrue);
  });

  test('Start trek is refused while a critical item is missing', () async {
    await app.finishSetup();
    await app.startTrek();
    expect(service.running, isFalse);
    expect(ui.sent, isEmpty);
  });

  test('Start trek starts the service, then tells the core', () async {
    perms.have.addAll([AppPermission.location, AppPermission.sms]);
    await app.addContact('+911111111111');
    await app.finishSetup();
    await app.refreshPermissions();
    await app.startTrek();
    expect(service.running, isTrue);
    expect(decodeCommand(ui.sent.single), isA<StartTrek>());
  });

  test('a trek the core reports as running opens the trek screen', () async {
    await app.finishSetup();
    ui.controller.add(stateJson(Activity.moving));
    expect(app.route, AppRoute.trek);
    ui.controller.add(stateJson(Activity.idle));
    expect(app.route, AppRoute.basecamp);
  });

  test('ending the trek stops the service and tells the core', () async {
    service.running = true;
    await app.endTrek();
    expect(service.running, isFalse);
    expect(decodeCommand(ui.sent.single), isA<EndTrek>());
  });

  test('the emergency card is stored and read back', () async {
    await app.saveCard(
      const EmergencyCard(
        bloodGroup: 'B+',
        allergies: 'Penicillin',
      ),
    );
    expect(app.card.bloodGroup, 'B+');
    expect(app.readiness.cardFilled, isTrue);
    expect(app.card.allergies, 'Penicillin');
  });
}
