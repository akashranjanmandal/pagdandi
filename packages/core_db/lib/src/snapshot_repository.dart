import 'package:core_db/src/database.dart';
import 'package:drift/drift.dart';

/// Persists trek state snapshots on every transition and restores the latest.
class SnapshotRepository {
  /// Creates the repository; only the newest [keep] snapshots are kept.
  SnapshotRepository(this._db, {this.keep = 20});

  final PagdandiDatabase _db;

  /// How many snapshots to keep.
  final int keep;

  /// Stores a snapshot and drops the oldest beyond [keep].
  Future<void> save(
    String json, {
    required int version,
    required DateTime at,
  }) => _db.transaction(() async {
    await _db
        .into(_db.stateSnapshots)
        .insert(
          StateSnapshotsCompanion.insert(
            takenAt: at,
            version: version,
            json: json,
          ),
        );
    final old =
        await (_db.select(_db.stateSnapshots)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1000000, offset: keep))
            .get();
    if (old.isNotEmpty) {
      await (_db.delete(
        _db.stateSnapshots,
      )..where((t) => t.id.isIn(old.map((r) => r.id)))).go();
    }
  });

  /// The newest snapshot, or null.
  Future<SnapshotRow?> latest() =>
      (_db.select(_db.stateSnapshots)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();

  /// How many snapshots are stored.
  Future<int> count() async =>
      (await _db.select(_db.stateSnapshots).get()).length;
}
