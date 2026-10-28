import 'package:core_model/core_model.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 10, 27, 14);

Transition step(TrekState s, TrekEvent e, {DateTime? now}) =>
    reduce(s, e, now ?? t0);

TrekState walking() => step(
  step(TrekState.idle, const StartTrek()).state,
  const MotionDetected(),
).state;

void main() {
  group('activity', () {
    test('starting a trek waits for motion and starts tracking', () {
      final t = step(TrekState.idle, const StartTrek());
      expect(t.state.activity, Activity.stationary);
      expect(t.effects, [const StartTracking()]);
    });

    test('motion makes you moving; stillness makes you stationary', () {
      final moving = walking();
      expect(moving.activity, Activity.moving);
      expect(
        step(moving, const StillnessDetected()).state.activity,
        Activity.stationary,
      );
    });

    test('motion or stillness while idle is ignored', () {
      expect(
        step(TrekState.idle, const MotionDetected()).state,
        TrekState.idle,
      );
      expect(
        step(TrekState.idle, const StillnessDetected()).state,
        TrekState.idle,
      );
    });

    test('starting twice changes nothing and does not restart tracking', () {
      final s = walking();
      final t = step(s, const StartTrek());
      expect(t.state, s);
      expect(t.effects, isEmpty);
    });

    test('ending a trek goes idle and stops tracking', () {
      final t = step(walking(), const EndTrek());
      expect(t.state.activity, Activity.idle);
      expect(t.effects, [const StopTracking()]);
    });

    test('ending a trek while idle does nothing', () {
      expect(step(TrekState.idle, const EndTrek()).effects, isEmpty);
    });

    test('a trek cannot be ended during an SOS', () {
      final sos = step(walking(), const SosPressed()).state;
      final t = step(sos, const EndTrek());
      expect(t.state.activity, isNot(Activity.idle));
      expect(t.effects, isEmpty);
    });

    test('the map overlay opens and closes without changing activity', () {
      final s = walking();
      final open = step(s, const MapOpened()).state;
      expect(open.mapOpen, isTrue);
      expect(open.activity, Activity.moving);
      expect(step(open, const MapClosed()).state.mapOpen, isFalse);
    });
  });

  group('SOS', () {
    test('holding SOS raises it, lights the beacon and buzzes', () {
      final t = step(walking(), const SosPressed());
      expect(t.state.emergency, const SosActive());
      expect(t.effects, [
        const RaiseSos(),
        const BeaconOn(),
        const Haptic(HapticPattern.sos),
      ]);
    });

    test('SOS works even before a trek has started', () {
      final t = step(TrekState.idle, const SosPressed());
      expect(t.state.emergency, const SosActive());
    });

    test('pressing SOS again while active changes nothing', () {
      final sos = step(walking(), const SosPressed()).state;
      final t = step(sos, const SosPressed());
      expect(t.state, sos);
      expect(t.effects, isEmpty);
    });

    test('cancelling SOS cancels the messages, beacon and buzz', () {
      final sos = step(walking(), const SosPressed()).state;
      final t = step(sos, const SosCancelled());
      expect(t.state.emergency, const NoEmergency());
      expect(t.effects, [
        const CancelSos(),
        const BeaconOff(),
        const CancelHaptic(),
      ]);
    });

    test('cancelling when there is no SOS does nothing', () {
      expect(step(walking(), const SosCancelled()).effects, isEmpty);
    });
  });

  group('fall', () {
    test('a suspected fall starts a 60 second countdown', () {
      final t = step(walking(), const FallSuspected());
      expect(
        t.state.emergency,
        FallCountdown(t0.add(const Duration(seconds: 60))),
      );
      expect(t.effects, [
        ScheduleFallDeadline(t0.add(const Duration(seconds: 60))),
        const ShowFallScreen(),
      ]);
    });

    test('I am OK cancels the countdown', () {
      final s = step(walking(), const FallSuspected()).state;
      final t = step(s, const FallCancelled());
      expect(t.state.emergency, const NoEmergency());
      expect(t.effects, [const CancelFallDeadline()]);
    });

    test('the deadline expiring sends the SOS', () {
      final s = step(walking(), const FallSuspected()).state;
      final t = step(s, const FallCountdownExpired());
      expect(t.state.emergency, const SosActive());
      expect(t.effects, contains(const RaiseSos()));
    });

    test('holding Send SOS now during the countdown sends it early', () {
      final s = step(walking(), const FallSuspected()).state;
      final t = step(s, const SosPressed());
      expect(t.state.emergency, const SosActive());
      expect(t.effects, contains(const CancelFallDeadline()));
      expect(t.effects, contains(const RaiseSos()));
    });

    test('a stale deadline after cancelling is ignored', () {
      final t = step(walking(), const FallCountdownExpired());
      expect(t.state.emergency, const NoEmergency());
      expect(t.effects, isEmpty);
    });

    test('I am OK with no countdown does nothing', () {
      expect(step(walking(), const FallCancelled()).effects, isEmpty);
    });

    test('a second suspected fall does not restart the countdown', () {
      final s = step(walking(), const FallSuspected()).state;
      final later = t0.add(const Duration(seconds: 20));
      final t = step(s, const FallSuspected(), now: later);
      expect(t.state, s);
      expect(t.effects, isEmpty);
    });

    test('a fall during an SOS is ignored', () {
      final sos = step(walking(), const SosPressed()).state;
      expect(step(sos, const FallSuspected()).effects, isEmpty);
    });
  });

  group('lost mode', () {
    test('entering lost mode lights the beacon and arms the SOS', () {
      final t = step(walking(), const LostModeEntered());
      expect(t.state.emergency, const LostMode());
      expect(t.effects, [const BeaconOn(), const ArmSos()]);
    });

    test('being found turns them off again', () {
      final lost = step(walking(), const LostModeEntered()).state;
      final t = step(lost, const FoundByGroup());
      expect(t.state.emergency, const NoEmergency());
      expect(t.effects, [const BeaconOff(), const DisarmSos()]);
    });

    test('lost mode is ignored during an SOS or a fall countdown', () {
      final sos = step(walking(), const SosPressed()).state;
      expect(step(sos, const LostModeEntered()).effects, isEmpty);
      final fall = step(walking(), const FallSuspected()).state;
      expect(step(fall, const LostModeEntered()).effects, isEmpty);
    });

    test('found when not lost does nothing', () {
      expect(step(walking(), const FoundByGroup()).effects, isEmpty);
    });

    test('pressing SOS while lost raises the SOS (beacon already on)', () {
      final lost = step(walking(), const LostModeEntered()).state;
      final t = step(lost, const SosPressed());
      expect(t.state.emergency, const SosActive());
      expect(t.effects, contains(const RaiseSos()));
    });
  });

  group('friend SOS', () {
    test('a friend SOS buzzes the SOS pattern and shows the takeover', () {
      final t = step(walking(), const FriendSosReceived('rahul'));
      expect(t.state.emergency, const FriendSos('rahul'));
      expect(t.effects, [
        const Haptic(HapticPattern.sos),
        const ShowFriendScreen('rahul'),
      ]);
    });

    test('acknowledging stops the buzz and returns to normal', () {
      final s = step(walking(), const FriendSosReceived('rahul')).state;
      final t = step(s, const FriendSosAcknowledged());
      expect(t.state.emergency, const NoEmergency());
      expect(t.effects, [const CancelHaptic()]);
    });

    test('my own SOS is never displaced by a friend SOS', () {
      final sos = step(walking(), const SosPressed()).state;
      final t = step(sos, const FriendSosReceived('rahul'));
      expect(t.state.emergency, const SosActive());
      expect(t.effects, [const ShowFriendScreen('rahul')]);
    });

    test('a friend SOS outranks a fall countdown it arrives during', () {
      final fall = step(walking(), const FallSuspected()).state;
      final t = step(fall, const FriendSosReceived('rahul'));
      expect(t.state.emergency, isA<FallCountdown>());
      expect(t.effects, [const ShowFriendScreen('rahul')]);
    });

    test('acknowledging with no friend SOS does nothing', () {
      expect(step(walking(), const FriendSosAcknowledged()).effects, isEmpty);
    });

    test('a second friend SOS replaces the first friend only', () {
      final s = step(walking(), const FriendSosReceived('rahul')).state;
      final t = step(s, const FriendSosReceived('anita'));
      expect(t.state.emergency, const FriendSos('anita'));
    });
  });

  group('purity and equality', () {
    test('reduce is deterministic: same input, same output', () {
      final a = step(walking(), const FallSuspected());
      final b = step(walking(), const FallSuspected());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('states and emergencies compare by value', () {
      expect(const FriendSos('a'), const FriendSos('a'));
      expect(const FriendSos('a'), isNot(const FriendSos('b')));
      expect(FallCountdown(t0), FallCountdown(t0));
      expect(const NoEmergency().hashCode, const NoEmergency().hashCode);
      expect(walking().hashCode, walking().hashCode);
      expect(walking(), isNot(TrekState.idle));
    });

    test('effects compare by value', () {
      expect(const Haptic(HapticPattern.sos), const Haptic(HapticPattern.sos));
      expect(
        const Haptic(HapticPattern.sos),
        isNot(const Haptic(HapticPattern.tap)),
      );
      expect(const StartTracking().hashCode, const StartTracking().hashCode);
    });

    test('the idle state is the documented default', () {
      expect(TrekState.idle.activity, Activity.idle);
      expect(TrekState.idle.emergency, const NoEmergency());
      expect(TrekState.idle.mapOpen, isFalse);
    });
  });
}
