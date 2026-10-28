import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:core_model/core_model.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

OutboxEntry entry(
  String id,
  DateTime at, {
  SmsStatus status = SmsStatus.queued,
  OutboxKind kind = OutboxKind.sos,
  DateTime? last,
}) => OutboxEntry(
  id: id,
  to: '+91A',
  body: 'help $id',
  kind: kind,
  status: status,
  attempts: 2,
  createdAt: at,
  nextAttemptAt: at.add(const Duration(seconds: 30)),
  lastAttemptAt: last,
);

LocationFix fix(double lat, DateTime t) => LocationFix(
  latitude: lat,
  longitude: 88.2,
  accuracyM: 6,
  gpsTime: t,
  altitudeM: 3100,
);

void main() {
  snapshotStoreTests();
  late PagdandiDatabase db;
  final t0 = DateTime.utc(2026, 10, 27, 14);

  setUp(() => db = PagdandiDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('SMS outbox', () {
    test('stores and returns every field, oldest first', () async {
      final store = DriftSmsOutboxStore(db);
      await store.put(entry('b', t0.add(const Duration(minutes: 1))));
      await store.put(
        entry(
          'a',
          t0,
          status: SmsStatus.sent,
          kind: OutboxKind.cancel,
          last: t0,
        ),
      );
      final all = await store.all();
      expect(all.map((e) => e.id), ['a', 'b']);
      expect(
        all.first,
        entry(
          'a',
          t0,
          status: SmsStatus.sent,
          kind: OutboxKind.cancel,
          last: t0,
        ),
      );
      expect(all.last.lastAttemptAt, isNull);
    });

    test('put with the same id replaces the row', () async {
      final store = DriftSmsOutboxStore(db);
      await store.put(entry('a', t0));
      await store.put(entry('a', t0).copyWith(status: SmsStatus.delivered));
      final all = await store.all();
      expect(all, hasLength(1));
      expect(all.single.status, SmsStatus.delivered);
    });

    test('the outbox survives closing and reopening a real file', () async {
      final dir = Directory.systemTemp.createTempSync('pagdandi_db');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/trek.sqlite');
      final first = PagdandiDatabase(NativeDatabase(file));
      await DriftSmsOutboxStore(first).put(entry('sos-1|+91A', t0));
      await first.close();
      final second = PagdandiDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final all = await DriftSmsOutboxStore(second).all();
      expect(all.single.id, 'sos-1|+91A');
      expect(all.single.attempts, 2);
    });

    test(
      'the database runs in WAL mode so the native guard can read it',
      () async {
        final dir = Directory.systemTemp.createTempSync('pagdandi_wal');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = PagdandiDatabase(
          NativeDatabase(File('${dir.path}/t.sqlite')),
        );
        addTearDown(file.close);
        final row = await file.customSelect('PRAGMA journal_mode').getSingle();
        expect(row.data.values.single, 'wal');
      },
    );
  });

  group('state snapshots', () {
    test('returns the latest snapshot', () async {
      final repo = SnapshotRepository(db);
      expect(await repo.latest(), isNull);
      await repo.save('{"a":1}', version: 1, at: t0);
      await repo.save(
        '{"a":2}',
        version: 1,
        at: t0.add(const Duration(seconds: 5)),
      );
      final s = (await repo.latest())!;
      expect(s.json, '{"a":2}');
      expect(s.version, 1);
      expect(s.takenAt, t0.add(const Duration(seconds: 5)));
    });

    test('keeps only the newest few so the table stays small', () async {
      final repo = SnapshotRepository(db, keep: 3);
      for (var i = 0; i < 10; i++) {
        await repo.save(
          '{"i":$i}',
          version: 1,
          at: t0.add(Duration(seconds: i)),
        );
      }
      expect(await repo.count(), 3);
      expect((await repo.latest())!.json, '{"i":9}');
    });
  });

  group('event log', () {
    test('appends and returns the most recent first', () async {
      final log = EventLogRepository(db);
      await log.append(at: t0, type: 'StartTrek', detail: '');
      await log.append(
        at: t0.add(const Duration(seconds: 1)),
        type: 'SosPressed',
        detail: 'hold',
      );
      final recent = await log.recent(10);
      expect(recent.map((e) => e.type), ['SosPressed', 'StartTrek']);
      expect(recent.first.detail, 'hold');
    });

    test('is bounded: the oldest rows are dropped', () async {
      final log = EventLogRepository(db, maxRows: 5);
      for (var i = 0; i < 12; i++) {
        await log.append(
          at: t0.add(Duration(seconds: i)),
          type: 'e$i',
          detail: '',
        );
      }
      final recent = await log.recent(100);
      expect(recent, hasLength(5));
      expect(recent.first.type, 'e11');
      expect(recent.last.type, 'e7');
    });

    test('recent respects the limit', () async {
      final log = EventLogRepository(db);
      for (var i = 0; i < 4; i++) {
        await log.append(
          at: t0.add(Duration(seconds: i)),
          type: 'e$i',
          detail: '',
        );
      }
      expect(await log.recent(2), hasLength(2));
    });
  });

  group('trips and track points', () {
    test('records a trip and its points in one batch', () async {
      final repo = TrackRepository(db);
      final trip = await repo.startTrip(name: 'Sandakphu', at: t0);
      await repo.addPoints(trip, [
        fix(27, t0),
        fix(27.001, t0.add(const Duration(seconds: 5))),
        fix(27.002, t0.add(const Duration(seconds: 10))),
      ]);
      final pts = await repo.points(trip);
      expect(pts.map((p) => p.latitude), [27.0, 27.001, 27.002]);
      expect(pts.first.altitudeM, 3100);
      expect(pts.first.accuracyM, 6);
    });

    test('points come back in time order even if added out of order', () async {
      final repo = TrackRepository(db);
      final trip = await repo.startTrip(name: 't', at: t0);
      await repo.addPoints(trip, [
        fix(2, t0.add(const Duration(seconds: 10))),
        fix(1, t0),
      ]);
      expect((await repo.points(trip)).map((p) => p.latitude), [1, 2]);
    });

    test('an empty batch is a no-op', () async {
      final repo = TrackRepository(db);
      final trip = await repo.startTrip(name: 't', at: t0);
      await repo.addPoints(trip, const []);
      expect(await repo.points(trip), isEmpty);
    });

    test(
      'ending a trip records when; the open trip can be found after restart',
      () async {
        final repo = TrackRepository(db);
        expect(await repo.openTrip(), isNull);
        final trip = await repo.startTrip(name: 'T', at: t0);
        expect((await repo.openTrip())!.id, trip);
        await repo.endTrip(trip, at: t0.add(const Duration(hours: 5)));
        expect(await repo.openTrip(), isNull);
      },
    );

    test('points of different trips are kept apart', () async {
      final repo = TrackRepository(db);
      final a = await repo.startTrip(name: 'a', at: t0);
      final b = await repo.startTrip(name: 'b', at: t0);
      await repo.addPoints(a, [fix(1, t0)]);
      await repo.addPoints(b, [
        fix(2, t0),
        fix(3, t0.add(const Duration(seconds: 1))),
      ]);
      expect(await repo.points(a), hasLength(1));
      expect(await repo.points(b), hasLength(2));
    });
  });

  group('settings', () {
    test('get returns null until set, then the value', () async {
      final s = SettingsRepository(db);
      expect(await s.get('handedness'), isNull);
      await s.set('handedness', 'left');
      expect(await s.get('handedness'), 'left');
    });

    test('set overwrites', () async {
      final s = SettingsRepository(db);
      await s.set('k', 'a');
      await s.set('k', 'b');
      expect(await s.get('k'), 'b');
    });
  });

  group('schema', () {
    test('waits for a busy database instead of failing at once', () async {
      final r = await db.customSelect('PRAGMA busy_timeout').getSingle();
      expect(r.data.values.first as int, greaterThanOrEqualTo(2000));
    });

    test('is version 3 and creates every table', () async {
      expect(db.schemaVersion, 3);
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final names = rows.map((r) => r.data['name']).toSet();
      for (final t in [
        'sms_outbox',
        'state_snapshots',
        'event_log',
        'trips',
        'track_points',
        'settings',
        'pins',
      ]) {
        expect(names, contains(t));
      }
    });
  });
}

void snapshotStoreTests() {
  group('DriftSnapshotStore (the port)', () {
    late PagdandiDatabase db;
    setUp(() => db = PagdandiDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('latest is null when nothing was saved', () async {
      expect(await DriftSnapshotStore(db).latest(), isNull);
    });

    test('returns the newest saved JSON', () async {
      final s = DriftSnapshotStore(db);
      await s.save('{"a":1}', at: DateTime.utc(2026));
      await s.save('{"a":2}', at: DateTime.utc(2026, 1, 1, 0, 0, 1));
      expect(await s.latest(), '{"a":2}');
    });
  });
}
