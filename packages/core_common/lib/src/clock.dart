/// Source of time for the whole app. Inject it; never call `DateTime.now()`.
abstract interface class Clock {
  /// Wall-clock time in UTC. The user can change it, so it can jump.
  DateTime now();

  /// Monotonic time since an arbitrary start (device boot). It never jumps.
  Duration elapsed();
}

/// [Clock] backed by the device clock.
class SystemClock implements Clock {
  /// Creates the system clock.
  SystemClock() : _watch = Stopwatch()..start();

  final Stopwatch _watch;

  @override
  DateTime now() => DateTime.now().toUtc();

  @override
  Duration elapsed() => _watch.elapsed;
}
