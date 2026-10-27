import 'package:core_common/src/clock.dart';
import 'package:meta/meta.dart';

/// A GPS time observation together with the monotonic time it was taken at.
@immutable
class GpsTimeReading {
  /// Creates a reading.
  const GpsTimeReading({
    required this.gpsTime,
    required this.monotonicAtReading,
  });

  /// UTC time reported by the GPS receiver.
  final DateTime gpsTime;

  /// [Clock.elapsed] when [gpsTime] was received.
  final Duration monotonicAtReading;
}

/// Supplies the latest GPS time reading, if any.
abstract interface class GpsTimeSource {
  /// The most recent reading, or null if no fix has ever been obtained.
  GpsTimeReading? get latest;
}

/// A point in time and whether it came from GPS.
@immutable
class Timestamp {
  /// Creates a timestamp.
  const Timestamp({required this.time, required this.gpsTrusted});

  /// UTC time.
  final DateTime time;

  /// True if derived from GPS time; false means plain system time (flagged).
  final bool gpsTrusted;

  @override
  bool operator ==(Object other) =>
      other is Timestamp &&
      other.time == time &&
      other.gpsTrusted == gpsTrusted;

  @override
  int get hashCode => Object.hash(time, gpsTrusted);

  @override
  String toString() => 'Timestamp($time, gpsTrusted: $gpsTrusted)';
}

/// GPS time is the trusted clock; system time is used only without a usable
/// fix and is flagged as untrusted. GPS time is advanced with the monotonic
/// clock, so changing the phone's date cannot move it.
class TrustedClock {
  /// Creates a trusted clock.
  TrustedClock({
    required this._system,
    required this._gps,
    this.maxReadingAge = const Duration(minutes: 30),
  });

  final Clock _system;
  final GpsTimeSource _gps;

  /// Readings older than this are no longer trusted.
  final Duration maxReadingAge;

  /// Current time: GPS-derived and trusted when possible, otherwise system
  /// time flagged untrusted.
  Timestamp now() {
    final gps = _trustedNow();
    if (gps != null) return Timestamp(time: gps, gpsTrusted: true);
    return Timestamp(time: _system.now(), gpsTrusted: false);
  }

  /// System time minus trusted time, or null without a trusted reading.
  /// Used to detect and report clock skew.
  Duration? get systemSkew {
    final gps = _trustedNow();
    return gps == null ? null : _system.now().difference(gps);
  }

  DateTime? _trustedNow() {
    final reading = _gps.latest;
    if (reading == null) return null;
    final age = _system.elapsed() - reading.monotonicAtReading;
    if (age.isNegative || age > maxReadingAge) return null;
    return reading.gpsTime.add(age);
  }
}
