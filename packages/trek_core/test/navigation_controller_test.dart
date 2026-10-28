import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_geo/core_geo.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';
import 'package:trek_core/trek_core.dart';

const origin = GeoPoint(30, 79);

class _Log implements Logger {
  final warnings = <String>[];
  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level == LogLevel.warn || level == LogLevel.error) {
      warnings.add(message);
    }
  }
}

Route route() {
  final pts = <RoutePoint>[];
  var p = origin;
  for (var i = 0; i <= 200; i++) {
    pts.add(RoutePoint(p.lat, p.lon));
    p = destination(p, bearing: 0, distanceM: 10);
  }
  final mid = destination(origin, bearing: 0, distanceM: 1000);
  return Route(
    id: 'r',
    name: 'R',
    points: pts,
    waypoints: [Waypoint('Lake', mid.lat, mid.lon)],
    attribution: 'a',
  );
}

LocationFix fix(double along, {double side = 0, int sec = 0}) {
  final p = destination(
    destination(origin, bearing: 0, distanceM: along),
    bearing: 90,
    distanceM: side,
  );
  return LocationFix(
    latitude: p.lat,
    longitude: p.lon,
    accuracyM: 8,
    gpsTime: DateTime.utc(2026, 12, 14, 6).add(Duration(seconds: sec)),
  );
}

void main() {
  late StreamController<LocationFix> fixes;
  late FakeHapticOutput haptics;
  late FakeClock clock;
  late _Log log;
  late bool emergency;
  late NavigationController nav;
  late FakeVoiceOutput voice;

  setUp(() {
    fixes = StreamController<LocationFix>.broadcast(sync: true);
    haptics = FakeHapticOutput();
    clock = FakeClock(DateTime.utc(2026, 12, 14, 6));
    log = _Log();
    emergency = false;
    voice = FakeVoiceOutput();
    nav = NavigationController(
      fixes: fixes.stream,
      haptics: haptics,
      voice: voice,
      clock: () => clock.now(),
      logger: log,
      emergencyActive: () => emergency,
    );
  });
  tearDown(() => nav.dispose());

  test('without a route there is no guidance and fixes are ignored', () {
    fixes.add(fix(100));
    expect(nav.view, isNull);
    expect(haptics.played, isEmpty);
  });

  test('with a route, a fix gives a navigation view', () {
    nav.setRoute(route());
    fixes.add(fix(400));
    final v = nav.view!;
    expect(v.routeId, 'r');
    expect(v.status, NavStatus.onRoute);
    expect(v.progressM, closeTo(400, 3));
    expect(v.nextName, 'Lake');
    expect(v.nextDistM, closeTo(600, 5));
  });

  test('changes are announced to listeners', () {
    nav.setRoute(route());
    var n = 0;
    nav.changes.listen((_) => n++);
    fixes.add(fix(400));
    fixes.add(fix(410, sec: 5));
    expect(n, 2);
  });

  test('before any fix the view shows the route at the start', () {
    nav.setRoute(route());
    expect(nav.view, isNull);
    expect(nav.route!.id, 'r');
  });

  group('haptics', () {
    void walkOff() {
      for (var i = 0; i < 3; i++) {
        fixes.add(fix(500 + i * 5.0, side: 80, sec: i * 5));
      }
    }

    test('going off route buzzes the off-route pattern and repeats', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      expect(haptics.played, [HapticPattern.offRoute]);
      expect(haptics.repeating, HapticPattern.offRoute);
    });

    test('getting back on the trail stops the buzzing', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      fixes.add(fix(520, side: 5, sec: 30));
      expect(haptics.repeating, isNull);
    });

    test('a wrong way is three short buzzes, once', () {
      nav.setRoute(route());
      for (var i = 0; i <= 7; i++) {
        fixes.add(fix(800 - i * 15.0, sec: i * 10));
      }
      expect(
        haptics.played.where((p) => p == HapticPattern.wrongWay),
        hasLength(1),
      );
    });

    test('reaching a checkpoint buzzes once', () {
      nav.setRoute(route());
      for (var i = 0; i < 6; i++) {
        fixes.add(fix(940 + i * 20.0, sec: i * 10));
      }
      expect(
        haptics.played.where((p) => p == HapticPattern.checkpoint),
        hasLength(1),
      );
      expect(nav.view!.reachedName, anyOf('Lake', isNull));
    });

    test('nothing buzzes during an SOS or fall', () {
      emergency = true;
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      expect(haptics.played, isEmpty);
    });

    test('ending an off-route buzz never cancels an SOS pattern', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      emergency = true;
      fixes.add(fix(520, side: 5, sec: 30));
      expect(
        haptics.repeating,
        HapticPattern.offRoute,
        reason: 'left alone: the SOS owns the motor now',
      );
    });
  });

  group('voice', () {
    void walkOff() {
      for (var i = 0; i < 3; i++) {
        fixes.add(fix(500 + i * 5.0, side: 80, sec: i * 5));
      }
    }

    test('going off route says how far, in the scripted words', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      expect(
        voice.said.last,
        matches(
          RegExp(
            r'^Warning\. You are (79|80|81|82) metres off the trail\. '
            r'Stop and check\.$',
          ),
        ),
      );
    });

    test('getting back says so', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      fixes.add(fix(520, side: 5, sec: 30));
      expect(voice.said.last, 'Back on the trail.');
    });

    test('a wrong way says to turn around', () {
      nav.setRoute(route());
      for (var i = 0; i <= 7; i++) {
        fixes.add(fix(800 - i * 15.0, sec: i * 10));
      }
      expect(
        voice.said,
        contains('You are heading back to the start. Turn around to continue.'),
      );
    });

    test('on the way home a wrong way does not mention the start', () {
      nav.setRoute(route(), reversed: true);
      for (var i = 0; i <= 7; i++) {
        fixes.add(fix(1200 + i * 15.0, sec: i * 10));
      }
      expect(
        voice.said,
        contains('You are heading the wrong way. Turn around to continue.'),
      );
    });

    test('a checkpoint is named when reached', () {
      nav.setRoute(route());
      for (var i = 0; i < 6; i++) {
        fixes.add(fix(940 + i * 20.0, sec: i * 10));
      }
      expect(voice.said, contains('Lake reached.'));
    });

    test('arriving at the end is announced once', () {
      nav.setRoute(route());
      fixes.add(fix(1900));
      fixes.add(fix(1985, sec: 20));
      fixes.add(fix(1990, sec: 40));
      expect(
        voice.said.where((l) => l.startsWith('You have arrived')),
        hasLength(1),
      );
    });

    test('nothing is said during an SOS or fall', () {
      emergency = true;
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      expect(voice.said, isEmpty);
    });

    test('a snooze silences the off-route voice too', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      nav.snooze(const Duration(minutes: 10));
      walkOff();
      expect(voice.said, isEmpty);
    });

    test('a failing voice never stops guidance', () {
      final n = NavigationController(
        fixes: fixes.stream,
        haptics: FakeHapticOutput(),
        voice: _BadVoice(),
        clock: () => clock.now(),
        logger: log,
        emergencyActive: () => false,
      )..setRoute(route());
      for (var i = 0; i < 3; i++) {
        fixes.add(fix(500 + i * 5.0, side: 80, sec: i * 5));
      }
      expect(n.view!.status, NavStatus.offRoute);
      n.dispose();
    });
  });

  group('snooze ("I know, exploring")', () {
    void walkOff() {
      for (var i = 0; i < 3; i++) {
        fixes.add(fix(500 + i * 5.0, side: 80, sec: i * 5));
      }
    }

    test('stops the off-route buzz and says until when', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      expect(haptics.repeating, HapticPattern.offRoute);
      nav.snooze(const Duration(minutes: 10));
      expect(haptics.repeating, isNull);
      expect(
        nav.view!.snoozedUntil,
        clock.now().add(const Duration(minutes: 10)),
      );
    });

    test('going off route while snoozed stays quiet', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      nav.snooze(const Duration(minutes: 10));
      walkOff();
      expect(haptics.played, isEmpty);
      expect(nav.view!.status, NavStatus.offRoute, reason: 'still shown');
    });

    test('the buzz comes back when the snooze ends and you are still off', () {
      fakeAsync((async) {
        final c = StreamController<LocationFix>.broadcast(sync: true);
        final h = FakeHapticOutput();
        final fc = FakeClock(DateTime.utc(2026, 12, 14, 6));
        final n = NavigationController(
          fixes: c.stream,
          haptics: h,
          clock: fc.now,
          logger: _Log(),
          emergencyActive: () => false,
        )..setRoute(route());
        c.add(fix(500));
        n.snooze(const Duration(minutes: 10));
        for (var i = 0; i < 3; i++) {
          c.add(fix(500 + i * 5.0, side: 80, sec: 10 + i * 5));
        }
        expect(h.played, isEmpty);
        fc.advance(const Duration(minutes: 11));
        // Still walking, still off the trail, when the snooze runs out.
        c.add(fix(560, side: 80, sec: 11 * 60 + 10));
        async.elapse(const Duration(seconds: 10));
        expect(h.repeating, HapticPattern.offRoute);
        expect(n.view!.snoozedUntil, isNull);
        n.dispose();
      });
    });

    test('resuming brings the buzz back at once', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      walkOff();
      nav.snooze(const Duration(minutes: 10));
      nav.resumeAlerts();
      expect(haptics.repeating, HapticPattern.offRoute);
      expect(nav.view!.snoozedUntil, isNull);
    });

    test('a wrong way is not silenced by the snooze', () {
      nav.setRoute(route());
      nav.snooze(const Duration(minutes: 10));
      for (var i = 0; i <= 7; i++) {
        fixes.add(fix(800 - i * 15.0, sec: i * 10));
      }
      expect(haptics.played, contains(HapticPattern.wrongWay));
    });

    test('snoozing with no route or no fix does nothing', () {
      nav.snooze(const Duration(minutes: 10));
      nav.resumeAlerts();
      expect(nav.view, isNull);
    });
  });

  group('GPS lost', () {
    test('silence for a minute is GPS lost, with one buzz', () {
      fakeAsync((async) {
        final c = StreamController<LocationFix>.broadcast(sync: true);
        final h = FakeHapticOutput();
        final fc = FakeClock(DateTime.utc(2026, 12, 14, 6));
        final n = NavigationController(
          fixes: c.stream,
          haptics: h,
          clock: fc.now,
          logger: _Log(),
          emergencyActive: () => false,
        )..setRoute(route());
        c.add(fix(500));
        fc.advance(const Duration(seconds: 90));
        async.elapse(const Duration(seconds: 90));
        expect(n.view!.status, NavStatus.gpsLost);
        expect(h.played, [HapticPattern.gpsLost]);
        n.dispose();
      });
    });
  });

  group('route changes', () {
    test('clearing the route clears guidance and stops the buzz', () {
      nav.setRoute(route());
      fixes.add(fix(500));
      for (var i = 0; i < 3; i++) {
        fixes.add(fix(500 + i * 5.0, side: 80, sec: i * 5));
      }
      nav.setRoute(null);
      expect(nav.view, isNull);
      expect(haptics.repeating, isNull);
    });

    test('reverse flips the way home and the view says so', () {
      nav.setRoute(route());
      nav.reverse();
      fixes.add(fix(1400));
      expect(nav.view!.reversed, isTrue);
      expect(nav.view!.progressM, closeTo(600, 3));
    });

    test('reversing with no route does nothing', () {
      nav.reverse();
      expect(nav.view, isNull);
    });
  });

  test('a failing haptic motor never stops guidance', () {
    final bad = _BadHaptics();
    final n = NavigationController(
      fixes: fixes.stream,
      haptics: bad,
      clock: () => clock.now(),
      logger: log,
      emergencyActive: () => false,
    )..setRoute(route());
    for (var i = 0; i < 3; i++) {
      fixes.add(fix(500 + i * 5.0, side: 80, sec: i * 5));
    }
    expect(n.view!.status, NavStatus.offRoute);
    n.dispose();
  });
}

class _BadVoice implements VoiceOutput {
  @override
  Future<void> speak(String text, {bool urgent = false}) async =>
      throw StateError('speaker');
  @override
  Future<void> stop() async => throw StateError('speaker');
}

class _BadHaptics implements HapticOutput {
  @override
  Future<void> play(HapticPattern pattern) async => throw StateError('motor');
  @override
  Future<void> cancel() async => throw StateError('motor');
}
