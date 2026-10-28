import 'package:core_db/src/database.dart';
import 'package:drift/drift.dart';

/// Bounded event log: appending drops the oldest rows beyond [maxRows].
class EventLogRepository {
  /// Creates the repository.
  EventLogRepository(this._db, {this.maxRows = 1000});

  final PagdandiDatabase _db;

  /// Most rows kept.
  final int maxRows;

  /// Appends one event.
  Future<void> append({
    required DateTime at,
    required String type,
    required String detail,
  }) => _db.transaction(() async {
    final id = await _db
        .into(_db.eventLog)
        .insert(
          EventLogCompanion.insert(at: at, type: type, detail: detail),
        );
    await (_db.delete(
      _db.eventLog,
    )..where((t) => t.id.isSmallerOrEqualValue(id - maxRows))).go();
  });

  /// The newest [limit] events, newest first.
  Future<List<EventRow>> recent(int limit) =>
      (_db.select(_db.eventLog)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .get();
}
