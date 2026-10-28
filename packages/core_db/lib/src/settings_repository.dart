import 'package:core_db/src/database.dart';

/// Key-value settings.
class SettingsRepository {
  /// Creates the repository.
  SettingsRepository(this._db);

  final PagdandiDatabase _db;

  /// The value for [key], or null.
  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Sets [key] to [value].
  Future<void> set(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: value),
      );
}
