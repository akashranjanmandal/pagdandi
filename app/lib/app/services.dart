import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/native.dart';
import 'package:native_bridge/native_bridge.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/client/core_client.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';
import 'package:pagdandi_app/routes/route_library.dart';

/// What the UI engine runs on: the controller and its link to the core.
class AppServices {
  /// Creates the services.
  const AppServices({required this.app, required this.client});

  /// Settings, permissions and the user's actions.
  final AppController app;

  /// The link to the headless core.
  final CoreClient client;
}

/// Builds the real services on the phone: the native bridge, the shared
/// database and the permission plugin. The UI listens before it registers,
/// so the relay's latest state is not lost.
Future<AppServices> bootstrapServices() async {
  final host = PagdandiHostApi();
  final events = NativeEvents()..install();
  final db = PagdandiDatabase(NativeDatabase(File(await host.databasePath())));
  final channel = NativeUiChannel(host, events);
  final client = CoreClient(channel: channel, register: channel.register);
  final app = AppController(
    client: client,
    settings: SettingsRepository(db),
    permissions: PlatformPermissionService(const HandlerPermissionApi()),
    service: NativeTrekService(host),
    routes: const AssetRouteLibrary(),
    siren: NativeSirenOutput(host),
    torch: NativeTorchOutput(host),
    dialer: NativeDialer(host),
    signal: await NativeSignalMonitor.create(host, events),
    manufacturer: () async =>
        (await DeviceInfoPlugin().androidInfo).manufacturer,
  );
  await client.connect();
  await app.load();
  return AppServices(app: app, client: client);
}
