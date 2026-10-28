import 'package:core_model/core_model.dart';
import 'package:engine_trekstate/src/effects.dart';
import 'package:engine_trekstate/src/events.dart';
import 'package:engine_trekstate/src/state.dart';
import 'package:meta/meta.dart';

/// How long the fall countdown lasts.
const Duration fallCountdown = Duration(seconds: 60);

/// The result of one event: the new state and what to do about it.
@immutable
class Transition {
  /// Creates a transition.
  const Transition(this.state, [this.effects = const []]);

  /// State after the event.
  final TrekState state;

  /// Work for the runtime, in order.
  final List<Effect> effects;

  @override
  bool operator ==(Object other) {
    if (other is! Transition || other.state != state) return false;
    if (other.effects.length != effects.length) return false;
    for (var i = 0; i < effects.length; i++) {
      if (other.effects[i] != effects[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(state, Object.hashAll(effects));
}

Transition _same(TrekState s) => Transition(s);

/// Pure transition function: no side effects, no clock, no randomness.
/// Events that make no sense in the current state are ignored.
Transition reduce(TrekState s, TrekEvent e, DateTime now) => switch (e) {
  StartTrek() =>
    s.activity != Activity.idle
        ? _same(s)
        : Transition(
            s.copyWith(activity: Activity.stationary),
            const [StartTracking()],
          ),
  EndTrek() =>
    s.activity == Activity.idle || s.emergency is SosActive
        ? _same(s)
        : Transition(
            s.copyWith(activity: Activity.idle),
            const [StopTracking()],
          ),
  MotionDetected() =>
    s.activity == Activity.stationary
        ? Transition(s.copyWith(activity: Activity.moving))
        : _same(s),
  StillnessDetected() =>
    s.activity == Activity.moving
        ? Transition(s.copyWith(activity: Activity.stationary))
        : _same(s),
  MapOpened() => Transition(s.copyWith(mapOpen: true)),
  MapClosed() => Transition(s.copyWith(mapOpen: false)),
  SosPressed() => _sos(s),
  SosCancelled() =>
    s.emergency is SosActive
        ? Transition(
            s.copyWith(emergency: const NoEmergency()),
            const [CancelSos(), BeaconOff(), CancelHaptic()],
          )
        : _same(s),
  FallSuspected() => s.emergency is NoEmergency ? _fall(s, now) : _same(s),
  FallCancelled() =>
    s.emergency is FallCountdown
        ? Transition(
            s.copyWith(emergency: const NoEmergency()),
            const [CancelFallDeadline()],
          )
        : _same(s),
  FallCountdownExpired() => s.emergency is FallCountdown ? _sos(s) : _same(s),
  LostModeEntered() =>
    s.emergency is NoEmergency
        ? Transition(
            s.copyWith(emergency: const LostMode()),
            const [BeaconOn(), ArmSos()],
          )
        : _same(s),
  FoundByGroup() =>
    s.emergency is LostMode
        ? Transition(
            s.copyWith(emergency: const NoEmergency()),
            const [BeaconOff(), DisarmSos()],
          )
        : _same(s),
  FriendSosReceived(:final friendId) => _friend(s, friendId),
  FriendSosAcknowledged() =>
    s.emergency is FriendSos
        ? Transition(
            s.copyWith(emergency: const NoEmergency()),
            const [CancelHaptic()],
          )
        : _same(s),
};

Transition _fall(TrekState s, DateTime now) {
  final deadline = now.add(fallCountdown);
  return Transition(
    s.copyWith(emergency: FallCountdown(deadline)),
    [ScheduleFallDeadline(deadline), const ShowFallScreen()],
  );
}

/// Raises my own SOS from any state; idempotent once active.
Transition _sos(TrekState s) {
  final e = s.emergency;
  if (e is SosActive) return _same(s);
  return Transition(
    s.copyWith(emergency: const SosActive()),
    [
      if (e is FallCountdown) const CancelFallDeadline(),
      const RaiseSos(),
      if (e is! LostMode) const BeaconOn(),
      const Haptic(HapticPattern.sos),
    ],
  );
}

/// A friend's SOS never displaces my own SOS or a fall countdown: those stay
/// in charge, but the friend alert is still shown.
Transition _friend(TrekState s, String friendId) {
  final e = s.emergency;
  if (e is SosActive || e is FallCountdown) {
    return Transition(s, [ShowFriendScreen(friendId)]);
  }
  return Transition(
    s.copyWith(emergency: FriendSos(friendId)),
    [const Haptic(HapticPattern.sos), ShowFriendScreen(friendId)],
  );
}
