import 'package:core_model/core_model.dart';
import 'package:meta/meta.dart';

/// Something the runtime must do as the result of a transition. The reducer
/// only returns these; it never does them.
@immutable
sealed class Effect {
  const Effect();

  /// Values that define equality.
  List<Object?> get props => const [];

  @override
  bool operator ==(Object other) {
    if (other is! Effect || other.runtimeType != runtimeType) return false;
    final a = props;
    final b = other.props;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(props));
}

/// Start the location pipeline.
final class StartTracking extends Effect {
  /// Creates the effect.
  const StartTracking();
}

/// Stop the location pipeline.
final class StopTracking extends Effect {
  /// Creates the effect.
  const StopTracking();
}

/// Raise the SOS (outbox, SMS).
final class RaiseSos extends Effect {
  /// Creates the effect.
  const RaiseSos();
}

/// Cancel the active SOS.
final class CancelSos extends Effect {
  /// Creates the effect.
  const CancelSos();
}

/// Queue an SOS to send at first signal (lost mode).
final class ArmSos extends Effect {
  /// Creates the effect.
  const ArmSos();
}

/// Drop an armed SOS (found).
final class DisarmSos extends Effect {
  /// Creates the effect.
  const DisarmSos();
}

/// Start the BLE beacon.
final class BeaconOn extends Effect {
  /// Creates the effect.
  const BeaconOn();
}

/// Stop the BLE beacon.
final class BeaconOff extends Effect {
  /// Creates the effect.
  const BeaconOff();
}

/// Play a haptic pattern.
final class Haptic extends Effect {
  /// Creates the effect.
  const Haptic(this.pattern);

  /// Which pattern.
  final HapticPattern pattern;

  @override
  List<Object?> get props => [pattern];
}

/// Stop any repeating haptic.
final class CancelHaptic extends Effect {
  /// Creates the effect.
  const CancelHaptic();
}

/// Schedule the exact alarm that ends the fall countdown.
final class ScheduleFallDeadline extends Effect {
  /// Creates the effect.
  const ScheduleFallDeadline(this.at);

  /// When it fires.
  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Cancel the fall alarm.
final class CancelFallDeadline extends Effect {
  /// Creates the effect.
  const CancelFallDeadline();
}

/// Show the full-screen fall countdown.
final class ShowFallScreen extends Effect {
  /// Creates the effect.
  const ShowFallScreen();
}

/// Show the full-screen friend alert.
final class ShowFriendScreen extends Effect {
  /// Creates the effect.
  const ShowFriendScreen(this.friendId);

  /// Which friend.
  final String friendId;

  @override
  List<Object?> get props => [friendId];
}
