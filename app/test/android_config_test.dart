import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  test('minSdk is 29 and targetSdk is the latest stable (37)', () {
    expect(gradle, contains('minSdk = 29'));
    expect(gradle, contains('targetSdk = 37'));
  });

  test('app label comes from the single kAppName definition', () {
    expect(gradle, contains('core_common/lib/src/app_name.dart'));
    expect(gradle, contains('resValue("string", "app_name"'));
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, isNot(contains('android:label="Pagdandi"')));
  });

  test('the file the build reads still defines kAppName on one line', () {
    final src = File('../packages/core_common/lib/src/app_name.dart')
        .readAsStringSync();
    expect(
      RegExp("const String kAppName = '([^']+)';").hasMatch(src),
      isTrue,
    );
  });

  test('the app is Android only', () {
    for (final d in ['ios', 'web', 'macos', 'windows', 'linux']) {
      expect(Directory(d).existsSync(), isFalse, reason: d);
    }
  });
}
