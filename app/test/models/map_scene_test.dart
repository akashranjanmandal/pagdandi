import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/map_scene.dart';
import 'package:pagdandi_app/models/nav_state.dart';

void main() {
  test('on route: you are on the route and three friends are in range', () {
    final s = MapScene.of(NavState.onRoute);
    expect(s.distanceToRoute(s.you), lessThan(1));
    expect(s.friends.length, 3);
    expect(s.friends.where((f) => f.outOfRange), isEmpty);
    expect(s.showJunctionHighlight, isFalse);
  });

  test('junction: you are before the junction and it is highlighted', () {
    final s = MapScene.of(NavState.junction);
    expect(s.distanceToRoute(s.you), lessThan(1));
    expect(s.youAlongRoute, lessThan(s.junctionAlongRoute));
    expect(s.showJunctionHighlight, isTrue);
  });

  test('off route: you are on the taken branch, away from the route', () {
    final s = MapScene.of(NavState.offRoute);
    expect(s.distanceToRoute(s.you), greaterThan(20));
    expect(s.takenBranch, isTrue);
    // you face back toward the junction
    final toJ = math.atan2(
      s.junction.dy - s.you.dy,
      s.junction.dx - s.you.dx,
    );
    final headingRad = (s.headingDeg - 90) * math.pi / 180;
    expect(math.cos(headingRad - toJ), greaterThan(0.99));
  });

  test('wrong way: you face backward along the route', () {
    final fwd = MapScene.of(NavState.onRoute).headingDeg;
    final back = MapScene.of(NavState.wrongWay).headingDeg;
    expect(((back - fwd) % 360 - 180).abs(), lessThan(0.001));
  });

  test('GPS lost: your position is uncertain (hollow)', () {
    expect(MapScene.of(NavState.gpsLost).hollowYou, isTrue);
    expect(MapScene.of(NavState.onRoute).hollowYou, isFalse);
  });

  test('regroup: Rahul is out of range and your beacon pulses', () {
    final s = MapScene.of(NavState.regroup);
    expect(s.friends.where((f) => f.outOfRange).map((f) => f.initials), ['RK']);
    expect(s.pulse, isTrue);
  });

  test('the breadcrumb ends at you', () {
    for (final st in NavState.values) {
      final s = MapScene.of(st);
      final end = s.breadcrumb.last;
      expect((end - s.you).distance, lessThan(8), reason: st.name);
    }
  });
}
