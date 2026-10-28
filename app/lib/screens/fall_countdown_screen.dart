import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/sos_colour.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/countdown_ring.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/ok_key.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/status_tag.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Where the fall flow is.
enum FallStage {
  /// Counting down.
  running,

  /// SOS was sent.
  sent,

  /// The person cancelled.
  cancelled,
}

/// Snapshot of the fall countdown.
@immutable
class FallView {
  /// Creates a view.
  const FallView({
    this.stage = FallStage.running,
    this.secondsLeft = 60,
    this.accuracy = 'GPS ±8 m',
    this.battery = 71,
    this.detail = 'Detected: hard impact, then no movement for 30 s',
  });

  /// Flow position.
  final FallStage stage;

  /// Whole seconds until SOS is sent.
  final int secondsLeft;

  /// "GPS ±8 m" or "GPS ±—" without a fix.
  final String accuracy;

  /// Battery percent.
  final int battery;

  /// What was detected, in words. The real app only says a fall was
  /// suspected; the design sample shows a fuller line.
  final String detail;
}

/// Shown over the lock screen after a fall: the safe action ("I'm OK") is the
/// biggest thing on screen; sending now needs a hold.
class FallCountdownScreen extends StatelessWidget {
  /// Creates the screen.
  const FallCountdownScreen({
    required this.view,
    this.onOk,
    this.onSendNow,
    this.onOpenSos,
    this.onBackToTrek,
    super.key,
  });

  /// What to show.
  final FallView view;

  /// "I'm OK" tapped.
  final VoidCallback? onOk;

  /// "Send SOS now" hold completed.
  final VoidCallback? onSendNow;

  /// Open the SOS screen.
  final VoidCallback? onOpenSos;

  /// Return to the trek.
  final VoidCallback? onBackToTrek;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    void noop() {}

    switch (view.stage) {
      case FallStage.running:
        return ScreenFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlanceStrip(
                accuracy: view.accuracy,
                battery: view.battery,
                tint: sosTint(p),
                tag: StatusTag(
                  icon: AppIcon.warn,
                  label: 'Fall detected',
                  color: p.warn,
                ),
              ),
              // The prompt text scale is capped so the OK key keeps its room.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    Text(
                      'Did you fall?',
                      textAlign: TextAlign.center,
                      style: TypeScale.display.copyWith(color: p.text),
                    ),
                    const SizedBox(height: 14),
                    Center(child: CountdownRing(secondsLeft: view.secondsLeft)),
                    const SizedBox(height: 8),
                    Text(
                      'seconds until SOS is sent',
                      textAlign: TextAlign.center,
                      style: TypeScale.body.copyWith(color: p.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      view.detail,
                      textAlign: TextAlign.center,
                      style: TypeScale.caption.copyWith(color: p.text2),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: OkKey(onPressed: onOk ?? noop),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Align(
                  alignment: prefs.leftHanded
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: HoldButton.wide(
                      label: 'Send SOS now · hold 3 s',
                      semanticsLabel: 'Send SOS now, hold 3 seconds',
                      icon: AppIcon.octagon,
                      seconds: 3,
                      color: sosColour(p),
                      onComplete: onSendNow ?? noop,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case FallStage.sent:
        return ScreenFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlanceStrip(
                accuracy: view.accuracy,
                battery: view.battery,
                tint: sosTint(p),
                tag: StatusTag(
                  icon: AppIcon.octagon,
                  label: 'SOS',
                  color: sosColour(p),
                ),
              ),
              const Expanded(
                child: BigInstruction(
                  title: 'SOS active',
                  sub: 'SMS will send at first signal',
                ),
              ),
              ThumbPanel(
                children: [
                  KeyButton(
                    variant: KeyVariant.primary,
                    icon: AppIcon.octagon,
                    label: 'Open SOS screen',
                    onPressed: onOpenSos ?? noop,
                  ),
                ],
              ),
            ],
          ),
        );
      case FallStage.cancelled:
        return ScreenFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlanceStrip(
                accuracy: view.accuracy,
                battery: view.battery,
                tint: p.surface,
                tag: StatusTag(icon: AppIcon.ok, label: 'OK', color: p.ok),
              ),
              const Expanded(
                child: BigInstruction(
                  title: 'Cancelled',
                  sub: 'No SOS was sent · tracking continues',
                ),
              ),
              ThumbPanel(
                children: [
                  KeyButton(
                    variant: KeyVariant.primary,
                    icon: AppIcon.back,
                    label: 'Back to trek',
                    onPressed: onBackToTrek ?? noop,
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }
}
