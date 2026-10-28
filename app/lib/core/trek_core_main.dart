import 'dart:io';

import 'package:core_common/core_common.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:native_bridge/native_bridge.dart';
import 'package:pagdandi_app/core/assemble.dart';

/// Writes to the Flutter debug log (the rotating on-device log comes later).
class DebugPrintLogger implements Logger {
  /// Creates the logger.
  const DebugPrintLogger();

  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => debugPrint(
    '[${level.name}] $tag: $message${error == null ? '' : ' ($error)'}',
  );
}

/// The headless entrypoint the Android foreground service launches in its own
/// FlutterEngine. It runs the whole trek core with no UI, so the trek keeps
/// going when the app is closed.
@pragma('vm:entry-point')
Future<void> trekCoreMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final events = NativeEvents()..install();
  final core = await assembleTrekCore(
    host: PagdandiHostApi(),
    events: events,
    openDatabase: (path) => NativeDatabase(File(path)),
    logger: const DebugPrintLogger(),
  );
  await core.start();
}
