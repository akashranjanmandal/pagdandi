import 'package:core_common/core_common.dart';

/// A [Clock] that only moves when told to, for deterministic tests.
class FakeClock implements Clock {
  /// Creates a clock whose wall time starts at [start].
  FakeClock(DateTime start) : _wall = start.toUtc();

  DateTime _wall;
  Duration _mono = Duration.zero;

  @override
  DateTime now() => _wall;

  @override
  Duration elapsed() => _mono;

  /// Moves wall and monotonic time forward by [d].
  void advance(Duration d) {
    if (d.isNegative) throw ArgumentError.value(d, 'd', 'must not be negative');
    _wall = _wall.add(d);
    _mono += d;
  }

  /// Sets the wall clock (the user changed the date); monotonic time is kept.
  void jumpWall(DateTime to) => _wall = to.toUtc();
}
