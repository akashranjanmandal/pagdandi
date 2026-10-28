import 'package:core_db/src/database.dart';
import 'package:core_db/src/snapshot_repository.dart';
import 'package:core_ports/core_ports.dart';

/// [SnapshotStore] backed by SQLite.
class DriftSnapshotStore implements SnapshotStore {
  /// Creates the store on [db]. [version] is the snapshot format version.
  DriftSnapshotStore(PagdandiDatabase db, {this.version = 1})
    : _repo = SnapshotRepository(db);

  final SnapshotRepository _repo;

  /// Snapshot format version recorded with each row.
  final int version;

  @override
  Future<void> save(String json, {required DateTime at}) =>
      _repo.save(json, version: version, at: at);

  @override
  Future<String?> latest() async => (await _repo.latest())?.json;
}
