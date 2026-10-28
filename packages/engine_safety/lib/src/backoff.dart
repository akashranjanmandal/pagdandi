import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Retry delays for the outbox: exponential, capped. An SOS is retried
/// forever; only the gap between tries is limited.
@immutable
class BackoffPolicy {
  /// Creates a policy (30 s, doubling, capped at 10 min).
  const BackoffPolicy({
    this.initial = const Duration(seconds: 30),
    this.factor = 2,
    this.max = const Duration(minutes: 10),
  });

  /// Delay after the first failed attempt.
  final Duration initial;

  /// Growth per attempt.
  final int factor;

  /// Longest delay.
  final Duration max;

  /// Delay to wait after the [attempt]-th failed attempt (1-based).
  Duration delayFor(int attempt) {
    final steps = math.min(math.max(attempt, 1) - 1, 24);
    var micros = initial.inMicroseconds;
    for (var i = 0; i < steps; i++) {
      micros *= factor;
      if (micros >= max.inMicroseconds) return max;
    }
    return Duration(microseconds: math.min(micros, max.inMicroseconds));
  }
}
