/// Tells the native safety guard that the Dart core is alive. If the beats
/// stop for more than 30 s the guard takes over (flushes SMS, warns, restarts).
// A port is a deliberate one-method interface: fakes and adapters implement it.
// ignore: one_member_abstracts
abstract interface class HeartbeatSink {
  /// Records a beat at [at].
  Future<void> beat(DateTime at);
}

/// Controls the foreground trek service.
abstract interface class TrekService {
  /// Starts the service (only from a user action).
  Future<void> start();

  /// Stops the service and ends the trek.
  Future<void> stop();
}
