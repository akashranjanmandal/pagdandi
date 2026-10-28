import 'package:core_model/core_model.dart';
import 'package:meta/meta.dart';

/// A GPS position as words and numbers for the screen. Built only from a real
/// fix; screens show "Waiting for GPS" when there is none.
@immutable
class ShownPosition {
  /// Creates a position from already-formatted parts.
  const ShownPosition({
    required this.latitude,
    required this.longitude,
    required this.altitudeM,
    required this.accuracyM,
    required this.gpsTimeMillis,
  });

  /// From a real fix.
  factory ShownPosition.fromFix(LocationFix fix) => ShownPosition(
    latitude: fix.latitude,
    longitude: fix.longitude,
    altitudeM: fix.altitudeM,
    accuracyM: fix.accuracyM,
    gpsTimeMillis: fix.gpsTime.millisecondsSinceEpoch,
  );

  /// Degrees north (negative is south).
  final double latitude;

  /// Degrees east (negative is west).
  final double longitude;

  /// Metres above sea level, if the receiver gave one.
  final double? altitudeM;

  /// Horizontal accuracy radius in metres.
  final double accuracyM;

  /// GPS time of the fix, milliseconds since the Unix epoch (UTC).
  final int gpsTimeMillis;

  /// "27.0410° N".
  String get latText =>
      '${latitude.abs().toStringAsFixed(4)}° ${latitude < 0 ? 'S' : 'N'}';

  /// "88.2663° E".
  String get lonText =>
      '${longitude.abs().toStringAsFixed(4)}° ${longitude < 0 ? 'W' : 'E'}';

  /// "3,102", or "—" when unknown (never zero).
  String get altitudeText {
    final a = altitudeM;
    if (a == null) return '—';
    return a.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  /// "GPS ±8 m".
  String get accuracyText => 'GPS ±${accuracyM.round()} m';

  /// "GPS time 14:32 UTC".
  String get timeText {
    final t = DateTime.fromMillisecondsSinceEpoch(gpsTimeMillis, isUtc: true);
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return 'GPS time $hh:$mm UTC';
  }

  /// What a screen reader says.
  String get spoken {
    final ns = latitude < 0 ? 'south' : 'north';
    final ew = longitude < 0 ? 'west' : 'east';
    final alt = altitudeM == null
        ? 'altitude unknown'
        : 'altitude ${altitudeM!.round()} metres';
    return 'Latitude ${latitude.abs().toStringAsFixed(4)} $ns, '
        'longitude ${longitude.abs().toStringAsFixed(4)} $ew, $alt';
  }
}
