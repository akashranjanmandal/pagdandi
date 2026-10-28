import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/widgets/checklist.dart';
import 'package:pagdandi_app/widgets/direction_dial.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/large_toggle.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/status_tag.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Where the lost-mode flow is.
enum LostStage {
  /// Stay where you are.
  lost,

  /// "Why do you need to move?" sheet is open.
  prompt,

  /// Guided backtrack along the breadcrumb.
  backtrack,

  /// Marked as found.
  found,
}

/// Why the person needs to move (sent to the group).
enum LostReason {
  /// Too cold.
  cold('Cold', AppIcon.cold),

  /// Danger where they are.
  danger('Danger here', AppIcon.warn),

  /// Getting dark.
  dark('Getting dark', AppIcon.moon);

  const LostReason(this.label, this.icon);

  /// Button text.
  final String label;

  /// Button icon.
  final AppIcon icon;
}

/// Snapshot of lost mode.
@immutable
class LostView {
  /// Creates a view.
  const LostView({
    this.stage = LostStage.lost,
    this.reason = LostReason.cold,
    this.groupReached = false,
    this.torch = false,
    this.siren = false,
    this.beacon = false,
    this.live = false,
    this.accuracy = 'GPS ±12 m',
    this.battery = 64,
  });

  /// Flow position.
  final LostStage stage;

  /// Reason given when moving.
  final LostReason reason;

  /// Whether the group has actually received our alert.
  final bool groupReached;

  /// Torch strobe on.
  final bool torch;

  /// Siren on.
  final bool siren;

  /// A real beacon is broadcasting (never claimed otherwise).
  final bool beacon;

  /// The real app: no group data exists yet, so no distances, group claims
  /// or backtrack are shown.
  final bool live;

  /// "GPS ±12 m" or "GPS ±—".
  final String accuracy;

  /// Battery percent.
  final int battery;
}

/// For the separated person: stay put, see where the group probably is, see
/// what the app is doing. Calm: one display line, three rows, no map.
class LostModeScreen extends StatelessWidget {
  /// Creates the screen.
  const LostModeScreen({
    required this.view,
    this.onMove,
    this.onReason,
    this.onStay,
    this.onFound,
    this.onTorch,
    this.onSiren,
    this.onBackToTrek,
    super.key,
  });

  /// What to show.
  final LostView view;

  /// "I need to move" tapped.
  final VoidCallback? onMove;

  /// A reason was chosen.
  final ValueChanged<LostReason>? onReason;

  /// "Stay here" tapped.
  final VoidCallback? onStay;

  /// "I'm found" hold completed.
  final VoidCallback? onFound;

  /// Torch toggled.
  final ValueChanged<bool>? onTorch;

  /// Siren toggled.
  final ValueChanged<bool>? onSiren;

  /// Back to the trek screen after being found.
  final VoidCallback? onBackToTrek;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    void noop() {}
    final found = view.stage == LostStage.found;

    final rows = [
      if (view.beacon)
        const ChecklistRow(
          icon: AppIcon.radar,
          label: 'Beacon broadcasting',
          status: 'on',
          state: RowState.live,
        ),
      const ChecklistRow(
        icon: AppIcon.octagon,
        label: 'SOS SMS armed, sends at first signal',
        status: 'armed',
        state: RowState.wait,
      ),
      if (!view.live)
        ChecklistRow(
          icon: AppIcon.people,
          label: view.groupReached ? 'Group alerted' : 'Group will be alerted',
          status: view.groupReached ? '3 received' : 'when in range',
          state: view.groupReached ? RowState.done : RowState.wait,
        ),
    ];

    final strip = GlanceStrip(
      accuracy: view.live ? view.accuracy : (found ? 'GPS ±6 m' : 'GPS ±12 m'),
      battery: view.live ? view.battery : 64,
      tint: found ? p.surface : p.tintSignal,
      tag: found
          ? StatusTag(icon: AppIcon.ok, label: 'Found', color: p.ok)
          : StatusTag(icon: AppIcon.stay, label: 'Lost mode', color: p.signal),
    );

    Widget distance(String value, String l1, String l2, double angle) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              DirectionDial(
                big: true,
                angle: angle,
                color: p.signal,
                semanticsLabel: '$value metres, $l1',
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: value,
                            style: TypeScale.display.copyWith(
                              color: p.text,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' m',
                            style: TypeScale.body.copyWith(color: p.text2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(l1, style: TypeScale.label.copyWith(color: p.text2)),
                    Text(l2, style: TypeScale.label.copyWith(color: p.text2)),
                  ],
                ),
              ),
            ],
          ),
        );

    final foundBtn = HoldButton.wide(
      label: 'I’m found · hold 3 s',
      semanticsLabel: "I'm found, hold 3 seconds",
      icon: AppIcon.ok,
      seconds: 3,
      color: p.ok,
      onComplete: onFound ?? noop,
    );

    late final Widget body;
    late final Widget thumb;
    switch (view.stage) {
      case LostStage.lost || LostStage.prompt:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BigInstruction(
              title: 'Stay where you are',
              sub: view.live
                  ? 'Keep still. Your SOS message is ready to send.'
                  : 'Your group is coming to your last position',
            ),
            if (!view.live) ...[
              distance(
                '320',
                'group’s last position',
                'seen 4 min ago · downhill',
                20,
              ),
              const SizedBox(height: 14),
            ],
            StatusChecklist(rows: rows),
          ],
        );
        thumb = ThumbPanel(
          children: [
            Row(
              children: [
                Expanded(
                  child: LargeToggle(
                    icon: AppIcon.torch,
                    label: 'Torch strobe',
                    value: view.torch,
                    onChanged: onTorch ?? (_) {},
                  ),
                ),
                SizedBox(width: UiScope.of(context).space(10)),
                Expanded(
                  child: LargeToggle(
                    icon: AppIcon.siren,
                    label: 'Siren',
                    value: view.siren,
                    onChanged: onSiren ?? (_) {},
                  ),
                ),
              ],
            ),
            if (!view.live)
              KeyButton(
                icon: AppIcon.walk,
                label: 'I need to move',
                onPressed: onMove ?? noop,
              ),
            foundBtn,
          ],
        );
      case LostStage.backtrack:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BigInstruction(
              title: 'Walk back slowly',
              sub: 'Follow your breadcrumb · stop if the ground looks unsafe',
            ),
            distance(
              '260',
              'to where your group last saw you',
              'reason sent: ${view.reason.label}',
              150,
            ),
            const SizedBox(height: 14),
            StatusChecklist(rows: rows),
          ],
        );
        thumb = ThumbPanel(
          children: [
            KeyButton(
              icon: AppIcon.stay,
              label: 'Stay here instead',
              onPressed: onStay ?? noop,
            ),
            foundBtn,
          ],
        );
      case LostStage.found:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BigInstruction(
              title: 'Marked as found',
              sub: 'Beacon off · SOS SMS disarmed',
            ),
            StatusChecklist(
              rows: [
                const ChecklistRow(
                  icon: AppIcon.radar,
                  label: 'Beacon',
                  status: 'off',
                  state: RowState.off,
                ),
                const ChecklistRow(
                  icon: AppIcon.octagon,
                  label: 'SOS SMS',
                  status: 'disarmed',
                  state: RowState.off,
                ),
                ChecklistRow(
                  icon: AppIcon.people,
                  label: 'Group told you are found',
                  status: view.groupReached
                      ? 'received'
                      : 'sends when in range',
                  state: view.groupReached ? RowState.done : RowState.wait,
                ),
              ],
            ),
          ],
        );
        thumb = ThumbPanel(
          children: [
            KeyButton(
              variant: KeyVariant.primary,
              icon: AppIcon.back,
              label: 'Back to trek',
              onPressed: onBackToTrek ?? noop,
            ),
          ],
        );
    }

    return ScreenFrame(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              strip,
              Expanded(child: SingleChildScrollView(child: body)),
              thumb,
            ],
          ),
          if (view.stage == LostStage.prompt) ...[
            const Scrim(),
            SheetPanel(
              title: 'Why do you need to move?',
              children: [
                for (final r in LostReason.values)
                  KeyButton(
                    icon: r.icon,
                    label: r.label,
                    onPressed: () => onReason?.call(r),
                  ),
                KeyButton(
                  icon: AppIcon.stay,
                  label: 'Stay here',
                  onPressed: onStay ?? noop,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
