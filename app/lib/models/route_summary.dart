import 'package:engine_navigation/engine_navigation.dart';
import 'package:meta/meta.dart';

/// A named place and how far it is from the start, in words.
@immutable
class SummaryPlace {
  /// Creates the entry.
  const SummaryPlace(this.name, this.kmText);

  /// Its name.
  final String name;

  /// "5.6 km".
  final String kmText;
}

/// Sunrise, sunset and a suggested turn-back time, in local time.
@immutable
class SunSummary {
  /// Creates the summary.
  const SunSummary(this.sunriseText, this.sunsetText, this.turnBackText);

  /// "06:57".
  final String sunriseText;

  /// "17:12".
  final String sunsetText;

  /// Three hours before sunset: be heading down by then.
  final String turnBackText;
}

/// What Basecamp tells about a chosen route, as words.
@immutable
class RouteSummary {
  const RouteSummary._({
    required this.name,
    required this.lengthText,
    required this.climbText,
    required this.elevationText,
    required this.places,
    required this.sun,
    required this.winterNote,
    required this.attribution,
  });

  /// Summarises [route] for the trek on [day], with times shown at
  /// [utcOffset] from UTC.
  factory RouteSummary.of(
    Route route, {
    required DateTime day,
    required Duration utcOffset,
  }) {
    String km(double m) => '${(m / 1000).toStringAsFixed(1)} km';
    String thousands(num v) => v.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final eles = route.hasElevation
        ? [for (final p in route.points) p.ele!]
        : const <double>[];
    final mid = route.geo[route.geo.length ~/ 2];
    final times = sunTimes(day, mid.lat, mid.lon);
    String clock(DateTime utc) {
      final t = utc.add(utcOffset);
      return '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
    }

    final winter = const {11, 12, 1, 2}.contains(day.month);
    return RouteSummary._(
      name: route.name,
      lengthText: km(route.totalM),
      climbText: route.hasElevation
          ? '+${thousands(route.climbM)} m climb'
          : null,
      elevationText: route.hasElevation
          ? '${thousands(eles.first)} to ${thousands(eles.last)} m'
          : null,
      places: [
        for (final c in route.checkpoints)
          SummaryPlace(c.name, km(c.distanceAlongM)),
      ],
      sun: times == null
          ? null
          : SunSummary(
              clock(times.sunrise),
              clock(times.sunset),
              clock(times.sunset.subtract(const Duration(hours: 3))),
            ),
      winterNote: winter
          ? 'Winter: snow and ice are likely above 3,000 m and it gets dark '
                'early. Carry a headlamp, warm layers and something for ice, '
                'and keep to your guide’s plan.'
          : null,
      attribution: route.attribution,
    );
  }

  /// Route name.
  final String name;

  /// "10.8 km".
  final String lengthText;

  /// "+1,426 m climb", or null without elevation.
  final String? climbText;

  /// "2,373 to 3,216 m", or null without elevation.
  final String? elevationText;

  /// Named places along it.
  final List<SummaryPlace> places;

  /// Sun times, or null when the sun does not rise and set that day.
  final SunSummary? sun;

  /// Winter advice, or null outside winter.
  final String? winterNote;

  /// Where the data comes from.
  final String attribution;
}
