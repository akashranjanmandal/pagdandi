import 'package:engine_navigation/engine_navigation.dart' show Route;
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:meta/meta.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/position.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';
import 'package:trek_core/trek_core.dart';

/// Which screen a running trek should show, with what to show on it.
sealed class ScreenChoice {
  const ScreenChoice();
}

/// The Active Trek screen.
final class TrekChoice extends ScreenChoice {
  /// Creates the choice.
  const TrekChoice(this.view);

  /// What to show.
  final ActiveTrekView view;
}

/// My own SOS.
final class SosChoice extends ScreenChoice {
  /// Creates the choice.
  const SosChoice(this.view);

  /// What to show.
  final SosView view;
}

/// The fall countdown.
final class FallChoice extends ScreenChoice {
  /// Creates the choice.
  const FallChoice(this.view);

  /// What to show.
  final FallView view;
}

/// Lost mode.
final class LostChoice extends ScreenChoice {
  /// Creates the choice.
  const LostChoice(this.view);

  /// What to show.
  final LostView view;
}

/// The real state of the SOS tools, or none when the phone has no such
/// hardware adapters.
@immutable
class SosTools {
  /// Creates the state.
  const SosTools({
    required this.siren,
    required this.torch,
    required this.signal,
  });

  /// Siren sounding.
  final bool siren;

  /// Torch strobe on.
  final bool torch;

  /// Any mobile signal (enough for 112).
  final bool signal;
}

/// Picks the screen for the core's state. [sinceReceived] is how long ago the
/// message arrived, so the countdown moves between messages without trusting
/// the phone's wall clock.
ScreenChoice chooseScreen(
  CoreStateMessage m,
  Duration sinceReceived, {
  SosTools? tools,
  Route? route,
}) {
  switch (m.state.emergency) {
    case SosActive():
      // Destructured: the colour-rule test would flag a field access.
      final CoreStateMessage(sos: progress) = m;
      final total = progress.total;
      return SosChoice(
        SosView(
          delivery: SosDelivery(
            total: total,
            delivered: progress.delivered.clamp(0, total),
          ),
          position: m.fix == null ? null : ShownPosition.fromFix(m.fix!),
          battery: m.battery,
          toolsAvailable: tools != null,
          siren: tools?.siren ?? false,
          torch: tools?.torch ?? false,
          signal: tools?.signal ?? false,
        ),
      );
    case FallCountdown(:final deadline):
      final left = deadline.difference(m.at) - sinceReceived;
      final seconds = left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
      return FallChoice(
        FallView(
          secondsLeft: seconds,
          accuracy: m.fix == null
              ? 'GPS ±—'
              : ShownPosition.fromFix(m.fix!).accuracyText,
          battery: m.battery,
          detail: 'A fall was suspected',
        ),
      );
    case LostMode():
      return LostChoice(
        LostView(
          live: true,
          accuracy: m.fix == null
              ? 'GPS ±—'
              : ShownPosition.fromFix(m.fix!).accuracyText,
          battery: m.battery,
        ),
      );
    case NoEmergency() || FriendSos():
      return TrekChoice(
        ActiveTrekView.fromCore(m, route: route, sinceReceived: sinceReceived),
      );
  }
}
