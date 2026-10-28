import 'package:core_db/src/database.dart';
import 'package:drift/drift.dart';

/// Markers the walker dropped. Bounded: the oldest make room for new ones.
class PinRepository {
  /// Creates the repository.
  PinRepository(this._db, {this.maxRows = 500});

  final PagdandiDatabase _db;

  /// Most pins kept.
  final int maxRows;

  /// Saves a pin; returns its id.
  Future<int> add({
    required DateTime at,
    required double lat,
    required double lon,
    required double? accuracyM,
    required String label,
  }) => _db.transaction(() async {
    final id = await _db
        .into(_db.pins)
        .insert(
          PinsCompanion.insert(
            at: at,
            lat: lat,
            lon: lon,
            accuracyM: Value(accuracyM),
            label: label,
          ),
        );
    await (_db.delete(
      _db.pins,
    )..where((t) => t.id.isSmallerOrEqualValue(id - maxRows))).go();
    return id;
  });

  /// Every pin, newest first.
  Future<List<PinRow>> all() =>
      (_db.select(_db.pins)..orderBy([(t) => OrderingTerm.desc(t.id)])).get();

  /// How many pins there are.
  Future<int> count() async {
    final c = _db.pins.id.count();
    final row = await (_db.selectOnly(_db.pins)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
