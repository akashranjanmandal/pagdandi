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

  test('release signing reads key.properties and falls back to debug', () {
    expect(gradle, contains('key.properties'));
    expect(gradle, contains('signingConfigs'));
    expect(gradle, contains('getByName("debug")'));
  });

  test('key material can never be committed', () {
    final ignore = File('../.gitignore').readAsStringSync();
    for (final pattern in ['*.jks', '*.keystore', 'key.properties']) {
      expect(ignore, contains(pattern), reason: pattern);
    }
  });

  test('the app is Android only', () {
    for (final d in ['ios', 'web', 'macos', 'windows', 'linux']) {
      expect(Directory(d).existsSync(), isFalse, reason: d);
    }
  });

  test('app data (contacts, SMS outbox, tracks) is never backed up', () {
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:dataExtractionRules='));
    final rules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    // Both cloud backup and device-to-device transfer exclude everything.
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
    expect(
      RegExp('<exclude domain="').allMatches(rules).length,
      greaterThan(5),
    );
  });

  test('the boot receiver is not exported (the system still reaches it)', () {
    final plugin = File(
      '../packages/native_bridge/android/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final receiver = RegExp(
      '<receiver[^>]*BootReceiver[^>]*>',
      dotAll: true,
    ).firstMatch(plugin)!.group(0)!;
    expect(receiver, contains('android:exported="false"'));
  });

  test('SMS results are received by a private, manifest-declared receiver', () {
    final plugin = File(
      '../packages/native_bridge/android/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final receiver = RegExp(
      '<receiver[^>]*SmsResultReceiver[^>]*>',
      dotAll: true,
    ).firstMatch(plugin)!.group(0)!;
    expect(receiver, contains('android:exported="false"'));
    expect(plugin, contains('SMS_DELIVERED'));
    expect(plugin, contains('SMS_SENT'));
  });

  test(
    'release shrinking keeps what WorkManager and the plugin load by name',
    () {
      // Without this the release app crashes at start-up (R8 removes the
      // constructor of WorkManager's generated database class).
      expect(gradle, contains('proguardFiles'));
      expect(gradle, contains('proguard-rules.pro'));
      final rules = File('android/app/proguard-rules.pro').readAsStringSync();
      expect(rules, contains('androidx.work.impl.WorkDatabase_Impl'));
      expect(rules, contains('app.pagdandi.pagdandi_native'));
    },
  );

  test('the headless core is launched by library and name, and both exist', () {
    // Flutter resolves a bare entry-point name only in the main script, so the
    // library must be named. Without it the core never starts.
    final launcher = File(
      '../packages/native_bridge/android/src/main/kotlin/app/pagdandi/'
      'pagdandi_native/CoreLauncher.kt',
    ).readAsStringSync();
    final lib = RegExp(
      'const val LIBRARY = "(package:[^"]+)"',
    ).firstMatch(launcher)?.group(1);
    final fn = RegExp(
      'const val ENTRYPOINT = "([^"]+)"',
    ).firstMatch(launcher)?.group(1);
    expect(lib, isNotNull, reason: 'LIBRARY constant missing');
    expect(
      launcher,
      contains(
        'DartEntrypoint(loader.findAppBundlePath(), LIBRARY, ENTRYPOINT)',
      ),
    );
    final path = lib!.replaceFirst('package:pagdandi_app/', 'lib/');
    final src = File(path).readAsStringSync();
    expect(src, contains("@pragma('vm:entry-point')"));
    expect(src, contains('Future<void> $fn()'));
  });
}
