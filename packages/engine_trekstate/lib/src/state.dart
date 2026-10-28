import 'package:meta/meta.dart';

/// Activity region.
enum Activity {
  /// No trek running.
  idle,

  /// Walking.
  moving,

  /// Standing still (tracking pauses).
  stationary,
}

/// Emergency region: at most one at a time.
@immutable
sealed class Emergency {
  const Emergency();
}

/// Nothing wrong.
final class NoEmergency extends Emergency {
  /// Creates the state.
  const NoEmergency();

  @override
  bool operator ==(Object other) => other is NoEmergency;

  @override
  int get hashCode => 0;
}

/// Counting down to an automatic SOS after a suspected fall.
final class FallCountdown extends Emergency {
  /// Creates the state; the SOS goes out at [deadline].
  const FallCountdown(this.deadline);

  /// When the SOS will be sent unless cancelled.
  final DateTime deadline;

  @override
  bool operator ==(Object other) =>
      other is FallCountdown && other.deadline == deadline;

  @override
  int get hashCode => Object.hash(1, deadline);
}

/// Separated from the group: beacon on, SOS armed.
final class LostMode extends Emergency {
  /// Creates the state.
  const LostMode();

  @override
  bool operator ==(Object other) => other is LostMode;

  @override
  int get hashCode => 2;
}

/// My own SOS is running.
final class SosActive extends Emergency {
  /// Creates the state.
  const SosActive();

  @override
  bool operator ==(Object other) => other is SosActive;

  @override
  int get hashCode => 3;
}

/// A friend sent an SOS (not acknowledged yet).
final class FriendSos extends Emergency {
  /// Creates the state for [friendId].
  const FriendSos(this.friendId);

  /// Who needs help.
  final String friendId;

  @override
  bool operator ==(Object other) =>
      other is FriendSos && other.friendId == friendId;

  @override
  int get hashCode => Object.hash(4, friendId);
}

/// The whole trek state (Activity and Emergency regions plus the map
/// overlay). Group and Navigation regions arrive in M2.
@immutable
class TrekState {
  /// Creates a state.
  const TrekState({
    required this.activity,
    required this.emergency,
    required this.mapOpen,
  });

  /// No trek, no emergency, map closed.
  static const TrekState idle = TrekState(
    activity: Activity.idle,
    emergency: NoEmergency(),
    mapOpen: false,
  );

  /// Activity region.
  final Activity activity;

  /// Emergency region.
  final Emergency emergency;

  /// Whether the map overlay is open.
  final bool mapOpen;

  /// Copy with changes.
  TrekState copyWith({
    Activity? activity,
    Emergency? emergency,
    bool? mapOpen,
  }) => TrekState(
    activity: activity ?? this.activity,
    emergency: emergency ?? this.emergency,
    mapOpen: mapOpen ?? this.mapOpen,
  );

  @override
  bool operator ==(Object other) =>
      other is TrekState &&
      other.activity == activity &&
      other.emergency == emergency &&
      other.mapOpen == mapOpen;

  @override
  int get hashCode => Object.hash(activity, emergency, mapOpen);
}
