import 'dart:math' as math;

import 'package:core_model/core_model.dart';

/// Spots a fall from accelerometer samples: weightlessness, then an impact,
/// then about 30 s of stillness. It only suspects: the runtime then starts
/// the countdown, in which "I'm OK" cancels it.
///
/// Walking, running and stumbling shake the phone all the time, so a person
/// who gets up resets the stillness. A phone dropped and left lying will look
/// like a fall; the countdown and the "I'm OK" key are the answer to that.
class FallDetector {
  /// Creates a detector; the defaults suit a phone in a pocket or on a pack.
  FallDetector({
    this.freeFall = 3.0,
    this.freeFallFor = const Duration(milliseconds: 80),
    this.impactWithin = const Duration(seconds: 1),
    this.impact = 25.0,
    this.hardImpact = 39.0,
    this.stillDeviation = 3.0,
    this.stillFor = const Duration(seconds: 30),
    this.candidateLasts = const Duration(minutes: 2),
    this.cooldown = const Duration(minutes: 5),
  });

  /// Magnitude below this (m/s^2) is weightlessness.
  final double freeFall;

  /// How long weightlessness must last to count.
  final Duration freeFallFor;

  /// An impact this soon after weightlessness belongs to it.
  final Duration impactWithin;

  /// Magnitude above this after weightlessness is an impact.
  final double impact;

  /// Magnitude above this is an impact even with no weightlessness.
  final double hardImpact;

  /// Deviation from gravity (m/s^2) above which the phone is moving.
  final double stillDeviation;

  /// Stillness needed after the impact.
  final Duration stillFor;

  /// How long an impact stays a candidate while waiting for stillness.
  final Duration candidateLasts;

  /// Quiet time after a report.
  final Duration cooldown;

  static const double _gravity = 9.80665;

  Duration? _lastAt;
  Duration? _freeSince;
  Duration? _freeEnded;
  Duration? _impactAt;
  Duration? _stillSince;
  Duration? _reportedAt;

  /// Feeds one sample; true exactly when a fall is suspected.
  bool onSample(AccelSample s) {
    final last = _lastAt;
    if (last != null && s.at <= last) return false;
    _lastAt = s.at;
    final m = math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z);

    // Weightlessness: remember how long it has lasted.
    if (m < freeFall) {
      _freeSince ??= s.at;
    } else {
      final since = _freeSince;
      if (since != null && s.at - since >= freeFallFor) _freeEnded = s.at;
      _freeSince = null;
    }

    final impactAt = _impactAt;
    if (impactAt == null) {
      final ended = _freeEnded;
      final afterFree =
          m > impact && ended != null && s.at - ended <= impactWithin;
      if (afterFree || m > hardImpact) {
        final reported = _reportedAt;
        if (reported == null || s.at - reported >= cooldown) {
          _impactAt = s.at;
          _stillSince = s.at;
        }
        _freeEnded = null;
      }
      return false;
    }

    if (s.at - impactAt > candidateLasts) {
      _impactAt = null;
      _stillSince = null;
      return false;
    }
    if ((m - _gravity).abs() > stillDeviation) {
      // Moving again (or the impact itself): the stillness starts over.
      _stillSince = s.at;
      return false;
    }
    if (s.at - _stillSince! >= stillFor) {
      _impactAt = null;
      _stillSince = null;
      _reportedAt = s.at;
      return true;
    }
    return false;
  }
}
