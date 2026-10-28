import 'package:engine_navigation/engine_navigation.dart';
import 'package:test/test.dart';

const _gpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
<metadata><name>Sample</name><copyright author="OSM &amp; friends"/></metadata>
<wpt lat="30.001" lon="79.0"><name>Lake &amp; Camp</name></wpt>
<trk><name>Sample trail</name><trkseg>
<trkpt lat="30.000" lon="79.0"><ele>2000</ele></trkpt>
<trkpt lat="30.001" lon="79.0"><ele>2010.5</ele></trkpt>
<trkpt lat="30.002" lon="79.0"><ele>2030</ele></trkpt>
</trkseg></trk></gpx>''';

void main() {
  test('reads points, elevation, waypoints, name and attribution', () {
    final r = parseGpx(_gpx, id: 'sample');
    expect(r.id, 'sample');
    expect(r.name, 'Sample trail');
    expect(r.points, hasLength(3));
    expect(r.points[1].ele, 2010.5);
    expect(r.waypoints.single.name, 'Lake & Camp');
    expect(r.attribution, 'OSM & friends');
    expect(r.totalM, closeTo(222, 3));
  });

  test('several track segments are joined in order', () {
    const g = '''
<gpx><trk><trkseg>
<trkpt lat="30.0" lon="79.0"/><trkpt lat="30.001" lon="79.0"/></trkseg>
<trkseg><trkpt lat="30.002" lon="79.0"/><trkpt lat="30.003" lon="79.0"/></trkseg>
</trk></gpx>''';
    expect(parseGpx(g, id: 'x').points, hasLength(4));
  });

  test('a route (rte/rtept) is read like a track', () {
    const g = '''
<gpx><rte><name>R</name>
<rtept lat="30.0" lon="79.0"/><rtept lat="30.001" lon="79.0"/></rte></gpx>''';
    final r = parseGpx(g, id: 'x');
    expect(r.name, 'R');
    expect(r.points, hasLength(2));
  });

  test('points without elevation are fine', () {
    const g = '''
<gpx><trk><trkseg>
<trkpt lat="30.0" lon="79.0"/><trkpt lat="30.001" lon="79.0"/></trkseg></trk></gpx>''';
    expect(parseGpx(g, id: 'x').hasElevation, isFalse);
  });

  test('a file that is not GPX is refused with a clear error', () {
    expect(() => parseGpx('not xml at all', id: 'x'), throwsFormatException);
    expect(() => parseGpx('<html></html>', id: 'x'), throwsFormatException);
  });

  test('a GPX with fewer than two points is refused', () {
    const g =
        '<gpx><trk><trkseg><trkpt lat="30" lon="79"/></trkseg></trk></gpx>';
    expect(() => parseGpx(g, id: 'x'), throwsFormatException);
  });

  test('impossible coordinates are refused, never clamped', () {
    const g = '''
<gpx><trk><trkseg>
<trkpt lat="95" lon="79"/><trkpt lat="30" lon="79"/></trkseg></trk></gpx>''';
    expect(() => parseGpx(g, id: 'x'), throwsFormatException);
  });

  test(
    'a jump of more than 5 km between points is refused as a broken file',
    () {
      const g = '''
<gpx><trk><trkseg>
<trkpt lat="30.0" lon="79.0"/><trkpt lat="31.0" lon="79.0"/></trkseg></trk></gpx>''';
      expect(() => parseGpx(g, id: 'x'), throwsFormatException);
    },
  );
}
