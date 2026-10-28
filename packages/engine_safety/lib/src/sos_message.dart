import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:meta/meta.dart';

/// Everything an SOS SMS says.
@immutable
class SosReport {
  /// Creates a report. [fix] is null when GPS has never had a fix: the SOS is
  /// still sent, saying the position is unknown.
  const SosReport({
    required this.name,
    required this.fix,
    required this.time,
    required this.batteryPercent,
  });

  /// Who needs help.
  final String name;

  /// Last position fix, if any.
  final LocationFix? fix;

  /// When the SOS was raised (GPS time when trusted).
  final Timestamp time;

  /// Phone battery.
  final int batteryPercent;
}

String _two(int v) => v.toString().padLeft(2, '0');

String _utc(DateTime t) {
  final u = t.toUtc();
  return '${u.year}-${_two(u.month)}-${_two(u.day)} '
      '${_two(u.hour)}:${_two(u.minute)} UTC';
}

/// The SOS text: who, position, accuracy, altitude, GPS time, battery and a
/// maps link. Short enough for one multipart SMS.
String formatSosMessage(SosReport r) {
  final f = r.fix;
  final b = StringBuffer('SOS ${r.name} needs help. ');
  if (f == null) {
    b.write('Position unknown (no GPS fix yet). ');
    b.write(
      'Time ${_utc(r.time.time)}${r.time.gpsTrusted ? '' : ' (phone clock)'}. ',
    );
  } else {
    b.write(
      '${f.latitude.toStringAsFixed(4)}, ${f.longitude.toStringAsFixed(4)} '
      '±${f.accuracyM.round()} m',
    );
    if (f.altitudeM != null) b.write(', alt ${f.altitudeM!.round()} m');
    b.write('. GPS time ${_utc(f.gpsTime)}. ');
  }
  b.write('Phone battery ${r.batteryPercent}%.');
  if (f != null) {
    b.write(' https://maps.google.com/?q=${f.latitude},${f.longitude}');
  }
  return b.toString();
}

/// The text sent when an SOS that may have reached contacts is cancelled.
String formatCancelMessage({required String name, required Timestamp time}) =>
    '$name is OK. SOS cancelled at ${_utc(time.time)}'
    '${time.gpsTrusted ? '' : ' (phone clock)'}.';
