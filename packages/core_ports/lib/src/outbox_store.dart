import 'package:core_model/core_model.dart';

/// Durable storage for the SMS outbox (SQLite in the app). Writes must
/// survive process death and reboot.
abstract interface class SmsOutboxStore {
  /// Inserts or replaces the entry with the same id.
  Future<void> put(OutboxEntry entry);

  /// Every entry, oldest first.
  Future<List<OutboxEntry>> all();
}
