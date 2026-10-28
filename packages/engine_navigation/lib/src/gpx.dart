import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/src/route.dart';
import 'package:xml/xml.dart';

/// The biggest jump between two points that is believed. A bigger one means
/// the file is broken (a missing stretch), and a route with a hole in it must
/// never be loaded quietly.
const double maxGpxJumpM = 5000;

/// Reads a GPX file (tracks, or a route) into a [Route]. Throws
/// [FormatException] for anything that cannot be trusted.
Route parseGpx(String source, {required String id}) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(source);
  } on XmlException catch (e) {
    throw FormatException('not a GPX file: ${e.message}');
  }
  final root = doc.rootElement;
  if (root.name.local != 'gpx') {
    throw const FormatException('not a GPX file: no <gpx> element');
  }
  Iterable<XmlElement> kids(XmlElement e, String name) =>
      e.childElements.where((c) => c.name.local == name);

  double coord(XmlElement e, String attr, double lo, double hi) {
    final v = double.tryParse(e.getAttribute(attr) ?? '');
    if (v == null || v < lo || v > hi) {
      throw FormatException('bad $attr "${e.getAttribute(attr)}"');
    }
    return v;
  }

  RoutePoint point(XmlElement e) {
    final lat = coord(e, 'lat', -90, 90);
    final lon = coord(e, 'lon', -180, 180);
    final ele = double.tryParse(kids(e, 'ele').firstOrNull?.innerText ?? '');
    return RoutePoint(lat, lon, ele: ele);
  }

  final points = <RoutePoint>[];
  String? name;
  for (final trk in kids(root, 'trk')) {
    name ??= kids(trk, 'name').firstOrNull?.innerText.trim();
    for (final seg in kids(trk, 'trkseg')) {
      points.addAll(kids(seg, 'trkpt').map(point));
    }
  }
  if (points.isEmpty) {
    for (final rte in kids(root, 'rte')) {
      name ??= kids(rte, 'name').firstOrNull?.innerText.trim();
      points.addAll(kids(rte, 'rtept').map(point));
    }
  }
  if (points.length < 2) {
    throw const FormatException('the GPX has fewer than two track points');
  }
  for (var i = 1; i < points.length; i++) {
    final gap = distanceM(points[i - 1].geo, points[i].geo);
    if (gap > maxGpxJumpM) {
      throw FormatException(
        'the GPX jumps ${gap.round()} m between two points: a stretch is '
        'missing',
      );
    }
  }
  final meta = kids(root, 'metadata').firstOrNull;
  name ??= meta == null ? null : kids(meta, 'name').firstOrNull?.innerText;
  final author = meta == null
      ? null
      : kids(meta, 'copyright').firstOrNull?.getAttribute('author');
  final waypoints = [
    for (final w in kids(root, 'wpt'))
      Waypoint(
        kids(w, 'name').firstOrNull?.innerText.trim() ?? 'Waypoint',
        coord(w, 'lat', -90, 90),
        coord(w, 'lon', -180, 180),
      ),
  ];
  return Route(
    id: id,
    name: (name == null || name.isEmpty) ? id : name,
    points: points,
    waypoints: waypoints,
    attribution: author ?? 'unknown source',
  );
}
