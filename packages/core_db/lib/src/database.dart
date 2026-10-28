import 'package:core_db/src/tables.dart';
import 'package:core_model/core_model.dart';
import 'package:drift/drift.dart';

part 'database.g.dart';

/// The app database (schema version 3). Runs in WAL mode so the native safety
/// guard can read the SMS outbox while the Dart core writes.
@DriftDatabase(
  tables: [
    SmsOutbox,
    StateSnapshots,
    EventLog,
    Trips,
    TrackPoints,
    Settings,
    Pins,
  ],
)
class PagdandiDatabase extends _$PagdandiDatabase {
  /// Opens the database on the given executor.
  PagdandiDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: columns owned by the native safety guard.
        await m.addColumn(smsOutbox, smsOutbox.guardStatus);
        await m.addColumn(smsOutbox, smsOutbox.guardAttempts);
        await m.addColumn(smsOutbox, smsOutbox.guardUpdatedAt);
      }
      if (from < 3) {
        // v3: pins the walker dropped.
        await m.createTable(pins);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode=WAL');
      // The native guard writes to the same file: wait, do not fail.
      await customStatement('PRAGMA busy_timeout=5000');
      await customStatement('PRAGMA foreign_keys=ON');
    },
  );
}
