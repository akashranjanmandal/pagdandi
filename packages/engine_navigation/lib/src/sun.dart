import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Sunrise and sunset for one day and place, in UTC.
@immutable
class SunTimes {
  /// Creates the times.
  const SunTimes(this.sunrise, this.sunset);

  /// Sunrise (UTC).
  final DateTime sunrise;

  /// Sunset (UTC).
  final DateTime sunset;

  /// Time left before sunset at [now] (negative once it has set).
  Duration untilSunset(DateTime now) => sunset.difference(now);
}

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

/// Sunrise and sunset on the UTC date of [day] at ([lat], [lon]) using the
/// NOAA solar equations (accurate to about a minute away from the poles), or
/// null when the sun does not rise or set that day (polar night or midnight
/// sun).
SunTimes? sunTimes(DateTime day, double lat, double lon) {
  final d = DateTime.utc(day.year, day.month, day.day);
  final dayOfYear = d.difference(DateTime.utc(d.year)).inDays + 1;
  // Fractional year in radians.
  final g = 2 * math.pi / 365 * (dayOfYear - 1 + (12 - 12) / 24);
  final eqTime =
      229.18 *
      (0.000075 +
          0.001868 * math.cos(g) -
          0.032077 * math.sin(g) -
          0.014615 * math.cos(2 * g) -
          0.040849 * math.sin(2 * g));
  final decl =
      0.006918 -
      0.399912 * math.cos(g) +
      0.070257 * math.sin(g) -
      0.006758 * math.cos(2 * g) +
      0.000907 * math.sin(2 * g) -
      0.002697 * math.cos(3 * g) +
      0.00148 * math.sin(3 * g);
  // Sun centre 0.833 degrees below the horizon at rise and set.
  final cosH =
      (math.cos(_rad(90.833)) / (math.cos(_rad(lat)) * math.cos(decl))) -
      math.tan(_rad(lat)) * math.tan(decl);
  if (cosH > 1 || cosH < -1) return null;
  final h = _deg(math.acos(cosH));
  final riseMin = 720 - 4 * (lon + h) - eqTime;
  final setMin = 720 - 4 * (lon - h) - eqTime;
  DateTime at(double minutes) =>
      d.add(Duration(seconds: (minutes * 60).round()));
  return SunTimes(at(riseMin), at(setMin));
}
