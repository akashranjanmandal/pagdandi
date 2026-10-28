import 'package:meta/meta.dart';

/// Everything that can happen to a trek. All state changes go through one
/// serialized queue of these.
@immutable
sealed class TrekEvent {
  const TrekEvent();
}

/// The user pressed Start trek.
final class StartTrek extends TrekEvent {
  /// Creates the event.
  const StartTrek();
}

/// The user ended the trek.
final class EndTrek extends TrekEvent {
  /// Creates the event.
  const EndTrek();
}

/// Significant motion detected.
final class MotionDetected extends TrekEvent {
  /// Creates the event.
  const MotionDetected();
}

/// No movement for a while.
final class StillnessDetected extends TrekEvent {
  /// Creates the event.
  const StillnessDetected();
}

/// The map overlay opened.
final class MapOpened extends TrekEvent {
  /// Creates the event.
  const MapOpened();
}

/// The map overlay closed.
final class MapClosed extends TrekEvent {
  /// Creates the event.
  const MapClosed();
}

/// The SOS hold completed (or "Send SOS now").
final class SosPressed extends TrekEvent {
  /// Creates the event.
  const SosPressed();
}

/// The SOS cancel hold completed.
final class SosCancelled extends TrekEvent {
  /// Creates the event.
  const SosCancelled();
}

/// Fall detection saw free fall, impact and stillness.
final class FallSuspected extends TrekEvent {
  /// Creates the event.
  const FallSuspected();
}

/// The user tapped "I'm OK".
final class FallCancelled extends TrekEvent {
  /// Creates the event.
  const FallCancelled();
}

/// The fall countdown deadline passed.
final class FallCountdownExpired extends TrekEvent {
  /// Creates the event.
  const FallCountdownExpired();
}

/// The phone decided it is separated from the group.
final class LostModeEntered extends TrekEvent {
  /// Creates the event.
  const LostModeEntered();
}

/// The user held "I'm found", or the group reached them.
final class FoundByGroup extends TrekEvent {
  /// Creates the event.
  const FoundByGroup();
}

/// A friend's SOS arrived.
final class FriendSosReceived extends TrekEvent {
  /// Creates the event.
  const FriendSosReceived(this.friendId);

  /// Who sent it.
  final String friendId;
}

/// The user acknowledged the friend's SOS ("Guide me there").
final class FriendSosAcknowledged extends TrekEvent {
  /// Creates the event.
  const FriendSosAcknowledged();
}
