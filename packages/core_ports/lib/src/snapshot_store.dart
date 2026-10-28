/// Durable storage for the trek state snapshot, written on every transition.
abstract interface class SnapshotStore {
  /// Saves [json] taken at [at].
  Future<void> save(String json, {required DateTime at});

  /// The newest saved snapshot, or null.
  Future<String?> latest();
}
