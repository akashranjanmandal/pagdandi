import 'dart:convert';

import 'package:core_model/core_model.dart';
import 'package:engine_health/engine_health.dart';
import 'package:engine_navigation/engine_navigation.dart' show NavStatus;
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:test/test.dart';
import 'package:trek_core/trek_core.dart';

void main() {
  group('commands', () {
    final accepted = <TrekEvent>[
      const StartTrek(),
      const EndTrek(),
      const SosPressed(),
      const SosCancelled(),
      const FallCancelled(),
      const FoundByGroup(),
      const FriendSosAcknowledged(),
      const LostModeEntered(),
      const MapOpened(),
      const MapClosed(),
    ];

    for (final e in accepted) {
      test('round-trips ${e.runtimeType}', () {
        expect(decodeCommand(encodeCommand(e)).runtimeType, e.runtimeType);
      });
    }

    test('sensor and network events cannot be sent by the UI', () {
      for (final e in <TrekEvent>[
        const MotionDetected(),
        const StillnessDetected(),
        const FallSuspected(),
        const FallCountdownExpired(),
        const FriendSosReceived('x'),
      ]) {
        expect(() => encodeCommand(e), throwsArgumentError, reason: '$e');
      }
    });

    test('a forged sensor command from outside is ignored on decode', () {
      expect(decodeCommand('{"c":"fallSuspected"}'), isNull);
      expect(decodeCommand('{"c":"motionDetected"}'), isNull);
      expect(decodeCommand('{"c":"friendSosReceived"}'), isNull);
    });

    test('garbage never decodes to a command', () {
      for (final bad in [
        '',
        '{{',
        '[]',
        '{"c":3}',
        '{"x":"startTrek"}',
        'null',
        '"startTrek"',
      ]) {
        expect(decodeCommand(bad), isNull, reason: bad);
      }
    });
  });

  group('navigation commands', () {
    test('snooze and resume round trip', () {
      expect(decodeNavCommand(encodeSnoozeAlerts()), NavCommand.snoozeAlerts);
      expect(decodeNavCommand(encodeResumeAlerts()), NavCommand.resumeAlerts);
      expect(decodeNavCommand(encodeReverseRoute()), NavCommand.reverseRoute);
    });

    test('anything else is not a navigation command', () {
      expect(decodeNavCommand(encodeCommand(const StartTrek())), isNull);
      expect(decodeNavCommand('nope'), isNull);
      expect(decodeNavCommand('{"c":"snoozeAlertsNow"}'), isNull);
    });

    test('they are not trek events', () {
      expect(decodeCommand(encodeSnoozeAlerts()), isNull);
      expect(decodeCommand(encodeResumeAlerts()), isNull);
    });
  });

  group('drop-pin command', () {
    test('round trips and is recognised only as itself', () {
      expect(isDropPinCommand(encodeDropPin()), isTrue);
      expect(isDropPinCommand(encodeCommand(const StartTrek())), isFalse);
      expect(isDropPinCommand('nope'), isFalse);
      expect(isDropPinCommand('{"c":"dropPins"}'), isFalse);
    });

    test('is not a trek event or a navigation command', () {
      expect(decodeCommand(encodeDropPin()), isNull);
      expect(decodeNavCommand(encodeDropPin()), isNull);
    });
  });

  test('the pin count survives the channel and defaults to zero', () {
    final m = CoreStateMessage(
      state: const TrekState(
        activity: Activity.moving,
        emergency: NoEmergency(),
        mapOpen: false,
      ),
      sos: const SosSummary.none(),
      issues: const [],
      stats: const TrekStats(
        distanceM: 1,
        climbM: 1,
        elapsed: Duration(seconds: 1),
        altitudeM: null,
      ),
      battery: 50,
      fix: null,
      at: DateTime.utc(2026, 12, 14),
      pinCount: 3,
    );
    expect(CoreStateMessage.decode(m.encode())!.pinCount, 3);
    final json = jsonDecode(m.encode()) as Map<String, Object?>..remove('pins');
    expect(CoreStateMessage.decode(jsonEncode(json))!.pinCount, 0);
  });

  group('reverse-route command', () {
    test('round trips and is recognised only as itself', () {
      expect(isReverseRouteCommand(encodeReverseRoute()), isTrue);
      expect(isReverseRouteCommand(encodeCommand(const StartTrek())), isFalse);
      expect(isReverseRouteCommand('not json'), isFalse);
      expect(isReverseRouteCommand('{"c":"reverseRoutes"}'), isFalse);
    });

    test('is not a trek event, so it can never reach the statechart', () {
      expect(decodeCommand(encodeReverseRoute()), isNull);
    });
  });

  group('navigation block', () {
    final nav = NavView(
      routeId: 'lohajung-brahmatal',
      routeName: 'Lohajung-Brahmatal',
      status: NavStatus.offRoute,
      progressM: 5560.5,
      remainingM: 5200,
      totalM: 10760.5,
      crossTrackM: 48.2,
      bearingToGoDeg: 271.5,
      headingDeg: 90,
      arrived: false,
      reversed: true,
      climbLeftM: 640,
      nextName: 'Brahm Tal (Brahmatal)',
      nextDistM: 5018,
      reachedName: 'Bhengal Tal (Bekaltal)',
      snoozedUntil: DateTime.utc(2026, 12, 14, 9, 30),
    );

    CoreStateMessage withNav(NavView? n) => CoreStateMessage(
      state: const TrekState(
        activity: Activity.moving,
        emergency: NoEmergency(),
        mapOpen: false,
      ),
      sos: const SosSummary.none(),
      issues: const [],
      stats: const TrekStats(
        distanceM: 1,
        climbM: 1,
        elapsed: Duration(seconds: 1),
        altitudeM: null,
      ),
      battery: 50,
      fix: null,
      at: DateTime.utc(2026, 12, 14),
      nav: n,
    );

    test('every field survives the channel', () {
      final back = CoreStateMessage.decode(withNav(nav).encode())!.nav!;
      expect(back.routeId, nav.routeId);
      expect(back.routeName, nav.routeName);
      expect(back.status, NavStatus.offRoute);
      expect(back.progressM, nav.progressM);
      expect(back.remainingM, nav.remainingM);
      expect(back.totalM, nav.totalM);
      expect(back.crossTrackM, nav.crossTrackM);
      expect(back.bearingToGoDeg, nav.bearingToGoDeg);
      expect(back.headingDeg, 90);
      expect(back.arrived, isFalse);
      expect(back.reversed, isTrue);
      expect(back.climbLeftM, 640);
      expect(back.nextName, nav.nextName);
      expect(back.nextDistM, nav.nextDistM);
      expect(back.reachedName, nav.reachedName);
      expect(back.snoozedUntil, DateTime.utc(2026, 12, 14, 9, 30));
    });

    test('a free trek has no navigation block', () {
      expect(CoreStateMessage.decode(withNav(null).encode())!.nav, isNull);
    });

    test('a message from before routes existed still reads', () {
      final json = jsonDecode(withNav(null).encode()) as Map<String, Object?>
        ..remove('nav');
      expect(CoreStateMessage.decode(jsonEncode(json))!.nav, isNull);
    });

    test('an unknown status makes the block unreadable, not wrong', () {
      final json = jsonDecode(withNav(nav).encode()) as Map<String, Object?>;
      (json['nav']! as Map<String, Object?>)['st'] = 'teleporting';
      expect(CoreStateMessage.decode(jsonEncode(json)), isNull);
    });

    test('optional parts may be missing', () {
      const bare = NavView(
        routeId: 'r',
        routeName: 'R',
        status: NavStatus.onRoute,
        progressM: 0,
        remainingM: 10,
        totalM: 10,
        crossTrackM: 0,
        bearingToGoDeg: 0,
        arrived: false,
        reversed: false,
        climbLeftM: 0,
      );
      final back = CoreStateMessage.decode(withNav(bare).encode())!.nav!;
      expect(
        [back.headingDeg, back.nextName, back.nextDistM, back.reachedName],
        [null, null, null, null],
      );
    });
  });

  group('state message', () {
    final t0 = DateTime.utc(2026, 10, 27, 14, 32, 15, 250);

    CoreStateMessage message({LocationFix? fix, double? alt = 3102}) =>
        CoreStateMessage(
          state: const TrekState(
            activity: Activity.moving,
            emergency: SosActive(),
            mapOpen: false,
          ),
          sos: const SosSummary(
            active: true,
            total: 3,
            queued: 1,
            sending: 0,
            sent: 0,
            delivered: 2,
            failed: 0,
            cancelled: 0,
          ),
          issues: const [
            IssueView(
              severity: 'critical',
              message: 'The sms permission is off',
              fixHint: 'Allow sms',
            ),
            IssueView(
              severity: 'warn',
              message: 'Battery at 12%',
              fixHint: 'Switch to Saver mode',
            ),
          ],
          stats: TrekStats(
            distanceM: 2400.5,
            climbM: 180,
            elapsed: const Duration(minutes: 65),
            altitudeM: alt,
          ),
          battery: 41,
          fix: fix,
          at: t0,
        );

    test('round-trips everything', () {
      final fix = LocationFix(
        latitude: 27.041,
        longitude: 88.2663,
        accuracyM: 8,
        gpsTime: t0,
        altitudeM: 3102,
      );
      final back = CoreStateMessage.decode(message(fix: fix).encode())!;
      expect(back.state.emergency, const SosActive());
      expect(back.state.activity, Activity.moving);
      expect(back.sos.delivered, 2);
      expect(back.sos.total, 3);
      expect(back.sos.active, isTrue);
      expect(back.issues.map((i) => i.message), [
        'The sms permission is off',
        'Battery at 12%',
      ]);
      expect(back.issues.first.severity, 'critical');
      expect(back.stats.distanceM, 2400.5);
      expect(back.stats.climbM, 180);
      expect(back.stats.elapsed, const Duration(minutes: 65));
      expect(back.stats.altitudeM, 3102);
      expect(back.battery, 41);
      expect(back.fix, fix);
      expect(back.at, t0);
    });

    test('no fix and no altitude round-trip as null', () {
      final back = CoreStateMessage.decode(message(alt: null).encode())!;
      expect(back.fix, isNull);
      expect(back.stats.altitudeM, isNull);
    });

    test('converts to the UI-facing issue list from watchdog issues', () {
      final v = IssueView.from(const StorageLow(10));
      expect(v.severity, 'critical');
      expect(v.message, 'Only 10 MB of storage left');
      expect(v.fixHint, isNotEmpty);
      expect(IssueView.from(const BatteryLow(10)).severity, 'warn');
    });

    test('a newer or damaged message is not understood and never throws', () {
      expect(CoreStateMessage.decode('{{'), isNull);
      expect(CoreStateMessage.decode('[]'), isNull);
      expect(CoreStateMessage.decode('{"v":99}'), isNull);
      expect(CoreStateMessage.decode('{"v":1}'), isNull);
      final ok = message().encode();
      expect(
        CoreStateMessage.decode(
          ok.replaceFirst('"battery":41', '"battery":"x"'),
        ),
        isNull,
      );
      expect(
        CoreStateMessage.decode(ok.replaceFirst('"state":', '"stat":')),
        isNull,
      );
    });
  });
}
