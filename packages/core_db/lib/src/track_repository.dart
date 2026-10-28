import 'package:core_db/src/database.dart';
import 'package:core_model/core_model.dart';
import 'package:drift/drift.dart';

/// Trips and their breadcrumb points.
class TrackRepository {
  /// Creates the repository.
  TrackRepository(this._db);

  final PagdandiDatabase _db;

  /// Starts a trip and returns its id.
  Future<int> startTrip({required String name, required DateTime at}) => _db
      .into(_db.trips)
      .insert(
        TripsCompanion.insert(name: name, startedAt: at),
      );

  /// Marks the trip as ended.
  Future<void> endTrip(int tripId, {required DateTime at}) =>
      (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
        TripsCompanion(endedAt: Value(at)),
      );

  /// The trip that has not ended (to resume after a restart), or null.
  Future<TripRow?> openTrip() =>
      (_db.select(_db.trips)
            ..where((t) => t.endedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();

  /// Writes accepted fixes in one batch (batched DB writes save battery).
  Future<void> addPoints(int tripId, List<LocationFix> fixes) async {
    if (fixes.isEmpty) return;
    await _db.batch(
      (b) => b.insertAll(_db.trackPoints, [
        for (final f in fixes)
          TrackPointsCompanion.insert(
            tripId: tripId,
            at: f.gpsTime,
            latitude: f.latitude,
            longitude: f.longitude,
            accuracyM: f.accuracyM,
            altitudeM: Value(f.altitudeM),
          ),
      ]),
    );
  }

  /// The points of a trip in time order.
  Future<List<TrackPointRow>> points(int tripId) =>
      (_db.select(_db.trackPoints)
            ..where((t) => t.tripId.equals(tripId))
            ..orderBy([(t) => OrderingTerm.asc(t.at)]))
          .get();
}
