/// Helpers for turning an OpenStreetMap hiking relation into a GPX file.
/// Pure functions, tested in test/route_tools_test.dart.
library;

import 'dart:math' as math;

/// A latitude, longitude pair in degrees.
typedef LatLon = (double, double);

/// Ways that do not meet end to start.
class RouteGapError implements Exception {
  /// Creates the error.
  RouteGapError(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'RouteGapError: $message';
}

double _metres(LatLon a, LatLon b) {
  const r = 6371008.8;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.$1 - a.$1);
  final dLon = rad(b.$2 - a.$2);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.$1)) *
          math.cos(rad(b.$1)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(h)));
}

/// Joins OSM ways into one path, reversing ways as needed. Ways must meet
/// within [toleranceM] metres; a bigger gap is an error (a route with a hole
/// in it must never be loaded quietly).
List<LatLon> chainWays(List<List<LatLon>> ways, {double toleranceM = 25}) {
  if (ways.isEmpty) throw ArgumentError('no ways to chain');
  final remaining = [for (final w in ways) List<LatLon>.of(w)];
  var path = remaining.removeAt(0);
  while (remaining.isNotEmpty) {
    var bestIdx = -1;
    var bestGap = double.infinity;
    var appendEnd = true;
    var reverseWay = false;
    for (var i = 0; i < remaining.length; i++) {
      final w = remaining[i];
      final options = <(double, bool, bool)>[
        (_metres(path.last, w.first), true, false),
        (_metres(path.last, w.last), true, true),
        (_metres(path.first, w.last), false, false),
        (_metres(path.first, w.first), false, true),
      ];
      for (final o in options) {
        if (o.$1 < bestGap) {
          bestGap = o.$1;
          bestIdx = i;
          appendEnd = o.$2;
          reverseWay = o.$3;
        }
      }
    }
    if (bestGap > toleranceM) {
      throw RouteGapError(
        'the nearest way is ${bestGap.round()} m from the path',
      );
    }
    var w = remaining.removeAt(bestIdx);
    if (reverseWay) w = w.reversed.toList();
    if (appendEnd) {
      path = [...path, ...w.skip(1)];
    } else {
      path = [...w.take(w.length - 1), ...path];
    }
  }
  return path;
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _ele(double? e) => e == null ? '' : '<ele>$e</ele>';

/// Writes a GPX 1.1 document with one track and named waypoints.
String writeGpx({
  required String name,
  required String attribution,
  required List<(double, double, double?)> points,
  required List<(String, double, double)> waypoints,
}) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<gpx version="1.1" creator="pagdandi route tool" '
      'xmlns="http://www.topografix.com/GPX/1/1">',
    )
    ..writeln('<metadata><name>${_esc(name)}</name>')
    ..writeln('<copyright author="${_esc(attribution)}"/></metadata>');
  for (final w in waypoints) {
    b.writeln(
      '<wpt lat="${w.$2}" lon="${w.$3}"><name>${_esc(w.$1)}</name></wpt>',
    );
  }
  b
    ..writeln('<trk><name>${_esc(name)}</name><trkseg>')
    ..writeln(
      [
        for (final p in points)
          '<trkpt lat="${p.$1}" lon="${p.$2}">${_ele(p.$3)}</trkpt>',
      ].join('\n'),
    )
    ..writeln('</trkseg></trk>')
    ..writeln('</gpx>');
  return b.toString();
}

/// Smooths elevations from a coarse elevation model: a median of 3 removes
/// single-sample spikes, then a short moving average removes the staircase.
List<double> smoothElevation(List<double> ele) {
  if (ele.length < 3) return List.of(ele);
  final med = List<double>.of(ele);
  for (var i = 1; i < ele.length - 1; i++) {
    final w = [ele[i - 1], ele[i], ele[i + 1]]..sort();
    med[i] = w[1];
  }
  final out = List<double>.of(med);
  for (var i = 0; i < med.length; i++) {
    // A symmetric window, so the ends of a climb are not pulled inward.
    final r = math.min(2, math.min(i, med.length - 1 - i));
    final lo = i - r;
    final hi = i + r;
    var sum = 0.0;
    for (var j = lo; j <= hi; j++) {
      sum += med[j];
    }
    out[i] = sum / (hi - lo + 1);
  }
  return out;
}
