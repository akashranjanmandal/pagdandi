// Long SQL literals are clearer on one line.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:core_model/core_model.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:test/test.dart';

/// The exact v1 shape of the table, as shipped in M1.
const _v1 = '''
CREATE TABLE sms_outbox (
  id TEXT NOT NULL,
  recipient TEXT NOT NULL,
  body TEXT NOT NULL,
  kind TEXT NOT NULL,
  status TEXT NOT NULL,
  attempts INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  next_attempt_at TEXT NOT NULL,
  last_attempt_at TEXT NULL,
  PRIMARY KEY (id)
);
''';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pagdandi_mig');
    file = File('${dir.path}/trek.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void makeV1WithRow() {
    final db = raw.sqlite3.open(file.path)
      ..execute(_v1)
      ..execute(
        "INSERT INTO sms_outbox VALUES ('sos-1|+91A','+91A','help me','sos','sent',2, "
        "'2026-10-27T14:00:00.000Z','2026-10-27T14:00:30.000Z','2026-10-27T14:00:00.000Z')",
      )
      ..execute('PRAGMA user_version = 1');
    db.close();
  }

  test('v1 to v2 keeps every existing outbox row', () async {
    makeV1WithRow();
    final db = PagdandiDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final rows = await DriftSmsOutboxStore(db).all();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'sos-1|+91A');
    expect(rows.single.body, 'help me');
    expect(rows.single.status, SmsStatus.sent);
    expect(rows.single.attempts, 2);
    expect(db.schemaVersion, 3);
  });

  test('the upgrade adds the native guard columns, empty', () async {
    makeV1WithRow();
    final db = PagdandiDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get(); // forces the upgrade to run
    final cols = (await db.customSelect('PRAGMA table_info(sms_outbox)').get())
        .map((r) => r.data['name'])
        .toSet();
    expect(
      cols,
      containsAll(['guard_status', 'guard_attempts', 'guard_updated_at']),
    );
    final row =
        (await db
                .customSelect(
                  'SELECT guard_status, guard_attempts, guard_updated_at FROM sms_outbox',
                )
                .getSingle())
            .data;
    expect(row['guard_status'], isNull);
    expect(row['guard_attempts'], 0);
    expect(row['guard_updated_at'], isNull);
  });

  test(
    'the new columns are the guards: Dart writes never touch them',
    () async {
      makeV1WithRow();
      final db = PagdandiDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await db.customStatement(
        "UPDATE sms_outbox SET guard_status = 'sent', guard_attempts = 3",
      );
      final store = DriftSmsOutboxStore(db);
      final e = (await store.all()).single;
      await store.put(e.copyWith(attempts: 5));
      final row =
          (await db
                  .customSelect(
                    'SELECT guard_status, guard_attempts FROM sms_outbox',
                  )
                  .getSingle())
              .data;
      expect(row['guard_status'], 'sent');
      expect(row['guard_attempts'], 3);
    },
  );

  test('a fresh install goes straight to v3 with the same columns', () async {
    final db = PagdandiDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final cols = (await db.customSelect('PRAGMA table_info(sms_outbox)').get())
        .map((r) => r.data['name'])
        .toSet();
    expect(
      cols,
      containsAll(['guard_status', 'guard_attempts', 'guard_updated_at']),
    );
    expect(db.schemaVersion, 3);
  });

  group('the guards delivery counts', () {
    test(
      'a message the guard delivered is delivered, even if Dart never heard',
      () async {
        makeV1WithRow();
        final db = PagdandiDatabase(NativeDatabase(file));
        addTearDown(db.close);
        await db.customStatement(
          "UPDATE sms_outbox SET guard_status = 'delivered'",
        );
        expect(
          (await DriftSmsOutboxStore(db).all()).single.status,
          SmsStatus.delivered,
        );
      },
    );

    test(
      'a cancelled message stays cancelled whatever the guard says',
      () async {
        makeV1WithRow();
        final db = PagdandiDatabase(NativeDatabase(file));
        addTearDown(db.close);
        await db.customStatement(
          "UPDATE sms_outbox SET status = 'cancelled', guard_status = 'delivered'",
        );
        expect(
          (await DriftSmsOutboxStore(db).all()).single.status,
          SmsStatus.cancelled,
        );
      },
    );

    test('other guard states do not change the Dart status', () async {
      makeV1WithRow();
      final db = PagdandiDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await db.customStatement("UPDATE sms_outbox SET guard_status = 'failed'");
      expect(
        (await DriftSmsOutboxStore(db).all()).single.status,
        SmsStatus.sent,
      );
    });
  });

  test('v2 to v3 adds the pins table and keeps everything else', () async {
    makeV1WithRow();
    // Open once so the file is at v2 shape, then pretend it never had pins.
    var db = PagdandiDatabase(NativeDatabase(file));
    await DriftSmsOutboxStore(db).all();
    await db.customStatement('DROP TABLE IF EXISTS pins');
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();

    db = PagdandiDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final repo = PinRepository(db);
    await repo.add(
      at: DateTime.utc(2026, 12, 14, 9),
      lat: 30.15,
      lon: 79.58,
      accuracyM: 6,
      label: 'Pin 1',
    );
    expect(await repo.all(), hasLength(1));
    expect(await DriftSmsOutboxStore(db).all(), hasLength(1));
  });
}
