import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts so text in widget and golden tests is measured and
/// drawn with the real Barlow faces instead of the test placeholder font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = await File('assets/fonts/$f').readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Barlow', ['Barlow-Regular.ttf', 'Barlow-Medium.ttf']);
  await load('BarlowCondensed', [
    'BarlowCondensed-Regular.ttf',
    'BarlowCondensed-Medium.ttf',
    'BarlowCondensed-SemiBold.ttf',
  ]);
  await testMain();
}
