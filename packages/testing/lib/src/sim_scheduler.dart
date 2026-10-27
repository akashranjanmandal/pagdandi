import 'dart:collection';

import 'package:testing/src/fake_clock.dart';

class _Event implements Comparable<_Event> {
  _Event(this.at, this.seq, this.run);
  final Duration at;
  final int seq;
  final void Function() run;

  @override
  int compareTo(_Event other) {
    final c = at.compareTo(other.at);
    return c != 0 ? c : seq.compareTo(other.seq);
  }
}

/// Runs scheduled callbacks in time order on a [FakeClock]. No real timers.
class SimScheduler {
  /// Creates a scheduler driving [clock].
  SimScheduler(this.clock);

  /// The clock that is advanced to each event.
  final FakeClock clock;
  final _queue = SplayTreeSet<_Event>();
  int _seq = 0;

  /// Schedules [run] to happen [delay] from now.
  void after(Duration delay, void Function() run) {
    _queue.add(_Event(clock.elapsed() + delay, _seq++, run));
  }

  /// Runs every event due within [d], advancing the clock to each, then to
  /// the end of the window.
  void runFor(Duration d) {
    final end = clock.elapsed() + d;
    while (_queue.isNotEmpty && _queue.first.at <= end) {
      final e = _queue.first;
      _queue.remove(e);
      final gap = e.at - clock.elapsed();
      if (gap > Duration.zero) clock.advance(gap);
      e.run();
    }
    final rest = end - clock.elapsed();
    if (rest > Duration.zero) clock.advance(rest);
  }
}
