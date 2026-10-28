import 'package:core_db/src/database.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:drift/drift.dart';

/// [SmsOutboxStore] backed by SQLite: survives process death and reboot.
class DriftSmsOutboxStore implements SmsOutboxStore {
  /// Creates the store on [_db].
  DriftSmsOutboxStore(this._db);

  final PagdandiDatabase _db;

  @override
  Future<void> put(OutboxEntry e) => _db
      .into(_db.smsOutbox)
      .insertOnConflictUpdate(
        SmsOutboxCompanion.insert(
          id: e.id,
          recipient: e.to,
          body: e.body,
          kind: e.kind,
          status: e.status,
          attempts: e.attempts,
          createdAt: e.createdAt,
          nextAttemptAt: e.nextAttemptAt,
          lastAttemptAt: Value(e.lastAttemptAt),
        ),
      );

  /// The native guard may have delivered a message while Dart was not
  /// running; that delivery counts, unless the SOS was cancelled meanwhile.
  static SmsStatus _effectiveStatus(OutboxRow r) {
    final guardDelivered = r.guardStatus == 'delivered';
    final open =
        r.status != SmsStatus.delivered && r.status != SmsStatus.cancelled;
    return guardDelivered && open ? SmsStatus.delivered : r.status;
  }

  @override
  Future<List<OutboxEntry>> all() async {
    final rows = await (_db.select(
      _db.smsOutbox,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return [
      for (final r in rows)
        OutboxEntry(
          id: r.id,
          to: r.recipient,
          body: r.body,
          kind: r.kind,
          status: _effectiveStatus(r),
          attempts: r.attempts,
          createdAt: r.createdAt,
          nextAttemptAt: r.nextAttemptAt,
          lastAttemptAt: r.lastAttemptAt,
        ),
    ];
  }
}
