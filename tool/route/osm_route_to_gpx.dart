// Builds a GPX file (with elevation) from an OpenStreetMap hiking relation.
//
//   dart run tool/route/osm_route_to_gpx.dart --relation 12155768 \
//     --out app/assets/routes/lohajung_brahmatal.gpx \
//     --wpt "Lohajung=30.1285,79.6190" --wpt "Brahm Tal=30.1770,79.5895"
//
// Needs the network once, at build time; the app itself never does. Route
// data is OpenStreetMap contributors, ODbL. Elevation is from Open-Meteo's
// free elevation model (about 90 m resolution), smoothed.
import 'dart:convert';
import 'dart:io';

import '../src/route_tools.dart';

const _ua = 'pagdandi-route-tool/0.1';

Future<Object?> _post(String url, String body) async {
  final c = HttpClient()..userAgent = _ua;
  try {
    final req = await c.postUrl(Uri.parse(url));
    req.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    req.write(body);
    final res = await req.close();
    final text = await utf8.decodeStream(res);
    if (res.statusCode != 200) throw HttpException('$url: ${res.statusCode}');
    return jsonDecode(text);
  } finally {
    c.close();
  }
}

Future<Object?> _get(String url) async {
  final c = HttpClient()..userAgent = _ua;
  try {
    final req = await c.getUrl(Uri.parse(url));
    final res = await req.close();
    final text = await utf8.decodeStream(res);
    if (res.statusCode != 200) throw HttpException('$url: ${res.statusCode}');
    return jsonDecode(text);
  } finally {
    c.close();
  }
}

Future<void> main(List<String> args) async {
  String? relation;
  String? out;
  final wpts = <(String, double, double)>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--relation':
        relation = args[++i];
      case '--out':
        out = args[++i];
      case '--wpt':
        final parts = args[++i].split('=');
        final ll = parts[1].split(',');
        wpts.add((parts[0], double.parse(ll[0]), double.parse(ll[1])));
    }
  }
  if (relation == null || out == null) {
    stderr.writeln('usage: --relation <id> --out <file.gpx> [--wpt n=lat,lon]');
    exit(64);
  }

  final q =
      '[out:json][timeout:90];relation($relation);out tags;'
      ' relation($relation);out geom;';
  final data =
      (await _post(
            'https://overpass-api.de/api/interpreter',
            'data=${Uri.encodeQueryComponent(q)}',
          ))!
          as Map<String, Object?>;
  final elements = (data['elements']! as List).cast<Map<String, Object?>>();
  final rel = elements.firstWhere((e) => e['members'] != null);
  final name = (rel['tags']! as Map)['name'] as String? ?? 'route $relation';
  final ways = <List<LatLon>>[
    for (final m in (rel['members']! as List).cast<Map<String, Object?>>())
      if (m['type'] == 'way')
        [
          for (final g in (m['geometry']! as List).cast<Map<String, Object?>>())
            ((g['lat']! as num).toDouble(), (g['lon']! as num).toDouble()),
        ],
  ];
  final path = chainWays(ways);
  stdout.writeln('$name: ${ways.length} ways, ${path.length} points');

  final ele = <double>[];
  for (var i = 0; i < path.length; i += 100) {
    final chunk = path.skip(i).take(100).toList();
    final url =
        'https://api.open-meteo.com/v1/elevation'
        '?latitude=${chunk.map((p) => p.$1).join(',')}'
        '&longitude=${chunk.map((p) => p.$2).join(',')}';
    final r = (await _get(url))! as Map<String, Object?>;
    ele.addAll(
      (r['elevation']! as List).map((e) => (e as num).toDouble()),
    );
  }
  final smooth = smoothElevation(ele);
  final gpx = writeGpx(
    name: name,
    attribution: 'OpenStreetMap contributors (ODbL); elevation Open-Meteo',
    points: [
      for (var i = 0; i < path.length; i++)
        (path[i].$1, path[i].$2, double.parse(smooth[i].toStringAsFixed(1))),
    ],
    waypoints: wpts,
  );
  File(out).createSync(recursive: true);
  File(out).writeAsStringSync(gpx);
  stdout.writeln('wrote $out');
}
