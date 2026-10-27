import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/nav_state.dart';

void main() {
  group('nextRotation takes the shortest way round', () {
    test('350 to 10 turns 20 degrees forward, not 340 back', () {
      expect(nextRotation(350, 10), closeTo(370, 1e-9));
    });
    test('10 to 350 turns 20 degrees back', () {
      expect(nextRotation(10, 350), closeTo(-10, 1e-9));
    });
    test('accumulated angles keep working', () {
      expect(nextRotation(370, 20), closeTo(380, 1e-9));
    });
    test('half a turn is allowed either way but stays within 180', () {
      expect((nextRotation(0, 180) - 0).abs(), lessThanOrEqualTo(180));
    });
    test('no change stays put', () {
      expect(nextRotation(45, 45), 45);
    });
  });

  group('NavState labels', () {
    test('every state has a distinct tag label', () {
      final labels = NavState.values.map((s) => s.tagLabel).toSet();
      expect(labels.length, NavState.values.length);
    });
    test('wording matches the design', () {
      expect(NavState.onRoute.tagLabel, 'On route');
      expect(NavState.junction.tagLabel, 'Junction ahead');
      expect(NavState.offRoute.tagLabel, 'Off route');
      expect(NavState.wrongWay.tagLabel, 'Wrong way');
      expect(NavState.gpsLost.tagLabel, 'GPS lost');
      expect(NavState.regroup.tagLabel, 'Regrouping');
    });
    test('every state has a distinct icon (shape, not colour only)', () {
      final icons = NavState.values.map((s) => s.icon).toSet();
      expect(icons.length, NavState.values.length);
    });
  });
}
