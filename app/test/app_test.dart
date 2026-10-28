import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_db/core_db.dart';
import 'package:core_ports/core_ports.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/app.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/app/pagdandi_root.dart';
import 'package:pagdandi_app/app/services.dart';
import 'package:pagdandi_app/client/core_client.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';
import 'package:pagdandi_app/screens/active_trek_screen.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';
import 'package:testing/testing.dart';

Future<void> pumpApp(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(720, 2400)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: PagdandiApp()));
  await tester.pump();
}

void main() {
  testWidgets('the gallery names the app and lists every screen', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text(kAppName), findsOneWidget);
    for (final t in [
      'Active Trek',
      'Lost mode',
      'Friend SOS',
      'Fall countdown',
      'SOS active',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('opening an entry shows that screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('On route'));
    await tester.pumpAndSettle();
    expect(find.byType(ActiveTrekScreen), findsOneWidget);
  });

  testWidgets('holding SOS on the trek opens the SOS screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('On route'));
    await tester.pump(const Duration(milliseconds: 400));
    final g = await tester.startGesture(tester.getCenter(find.text('SOS')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));
    await g.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SosActiveScreen), findsOneWidget);
  });

  testWidgets('the fall countdown cancels with a single tap on I am OK', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.text('Countdown running'));
    await tester.pump();
    await tester.tap(find.text('Countdown running'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FallCountdownScreen), findsOneWidget);
    await tester.tap(find.text('I’m OK'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.descendant(
        of: find.byType(FallCountdownScreen),
        matching: find.text('Cancelled'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the sunlight switch changes the palette for every screen', (
    tester,
  ) async {
    await pumpApp(tester);
    UiPrefs prefs() => UiScope.of(tester.element(find.text(kAppName)));
    expect(prefs().palette, Palette.normal);
    await tester.tap(find.text('Sunlight'));
    await tester.pump();
    expect(prefs().palette, Palette.sunlight);
  });

  testWidgets('left-handed and glove switches reach the screens', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Left-handed'));
    await tester.tap(find.text('Glove'));
    await tester.pump();
    final p = UiScope.of(tester.element(find.text(kAppName)));
    expect(p.leftHanded, isTrue);
    expect(p.glove, isTrue);
  });

  testWidgets('with a bootstrap, the real app opens Setup on a first run', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(720, 2400)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final services = await tester.runAsync(fakeServices);
    await tester.pumpWidget(
      ProviderScope(
        child: PagdandiApp(bootstrap: () async => services!),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Which hand holds your phone?'), findsOneWidget);
    expect(find.text('Active Trek'), findsNothing, reason: 'not the gallery');
  });

  testWidgets('a saved left-handed choice is applied at startup', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(720, 2400)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final services = await tester.runAsync(() async {
      final s = await fakeServices();
      await s.app.setLeftHanded(left: true);
      return s;
    });
    await tester.pumpWidget(
      ProviderScope(child: PagdandiApp(bootstrap: () async => services!)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final scope = UiScope.of(tester.element(find.byType(PagdandiRoot)));
    expect(scope.leftHanded, isTrue);
  });

  testWidgets('while starting it shows the app name, never a blank screen', (
    tester,
  ) async {
    final never = Completer<AppServices>();
    await tester.pumpWidget(
      ProviderScope(child: PagdandiApp(bootstrap: () => never.future)),
    );
    await tester.pump();
    expect(find.text(kAppName), findsOneWidget);
  });

  testWidgets('a failed start says so plainly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: PagdandiApp(bootstrap: () async => throw StateError('boom')),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('could not start'), findsOneWidget);
  });
}

Future<AppServices> fakeServices() async {
  final db = PagdandiDatabase(NativeDatabase.memory());
  final ui = _Ui();
  final client = CoreClient(channel: ui, register: () async {});
  final app = AppController(
    client: client,
    settings: SettingsRepository(db),
    permissions: _Perms(),
    service: FakeTrekService(),
  );
  await client.connect();
  await app.load();
  return AppServices(app: app, client: client);
}

class _Perms implements PermissionService {
  @override
  Future<bool> isPermanentlyDenied(AppPermission p) async => false;
  @override
  Future<Set<AppPermission>> granted() async => {};
  @override
  Future<bool> request(AppPermission p) async => false;
  @override
  Future<void> openSettings() async {}
}

class _Ui implements UiChannel {
  @override
  Stream<String> get states => const Stream.empty();
  @override
  Future<void> send(String json) async {}
}
