import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/sos_colour.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/position.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/widgets/checklist.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/large_toggle.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/status_tag.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// The design sample's position. Only for previews and tests; the real app
/// always passes the real fix (or null).
const _samplePosition = ShownPosition(
  latitude: 27.041,
  longitude: 88.2663,
  altitudeM: 3102,
  accuracyM: 8,
  gpsTimeMillis: 1793111520000, // 2026-10-27 14:32 UTC
);

/// Snapshot of an active SOS.
@immutable
class SosView {
  /// Creates a view.
  const SosView({
    this.delivery = const SosDelivery(total: 3, delivered: 0),
    this.signal = false,
    this.siren = false,
    this.torch = false,
    this.cancelled = false,
    this.position = _samplePosition,
    this.battery = 41,
    this.toolsAvailable = true,
  });

  /// How far the SMS has got.
  final SosDelivery delivery;

  /// Any mobile signal (enables Call 112).
  final bool signal;

  /// Siren on.
  final bool siren;

  /// Torch strobe on.
  final bool torch;

  /// SOS was cancelled.
  final bool cancelled;

  /// Where the phone is, or null while there is no GPS fix.
  final ShownPosition? position;

  /// Battery percent.
  final int battery;

  /// Whether siren, torch and Call 112 exist. False in the real app until
  /// they are built: a key that does nothing is worse than no key.
  final bool toolsAvailable;
}

/// My SOS is running: coordinates to read aloud, an honest delivery status,
/// and the few controls I might need. No decorative motion.
class SosActiveScreen extends StatelessWidget {
  /// Creates the screen.
  const SosActiveScreen({
    required this.view,
    this.onSiren,
    this.onTorch,
    this.onCall,
    this.onCancel,
    this.onBackToTrek,
    super.key,
  });

  /// What to show.
  final SosView view;

  /// Siren toggled.
  final ValueChanged<bool>? onSiren;

  /// Torch toggled.
  final ValueChanged<bool>? onTorch;

  /// Call 112.
  final VoidCallback? onCall;

  /// Cancel hold completed.
  final VoidCallback? onCancel;

  /// Back to the trek after cancelling.
  final VoidCallback? onBackToTrek;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    void noop() {}

    if (view.cancelled) {
      return ScreenFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlanceStrip(
              accuracy: view.position?.accuracyText ?? 'GPS ±—',
              battery: view.battery,
              tint: p.surface,
              tag: StatusTag(
                icon: AppIcon.ok,
                label: 'SOS cancelled',
                color: p.ok,
              ),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BigInstruction(
                    title: 'SOS cancelled',
                    sub:
                        'Cancel message will send at first signal · beacon off',
                  ),
                  StatusChecklist(
                    rows: [
                      ChecklistRow(
                        icon: AppIcon.send,
                        label: 'Cancel message to contacts who may have it',
                        status: 'queued',
                        state: RowState.wait,
                      ),
                      ChecklistRow(
                        icon: AppIcon.radar,
                        label: 'Beacon',
                        status: 'off',
                        state: RowState.off,
                      ),
                    ],
                  ),
                ],
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

    final d = view.delivery;
    final groupDone = d.delivered > 0;
    return ScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlanceStrip(
            accuracy: view.position?.accuracyText ?? 'GPS ±—',
            battery: view.battery,
            tint: sosTint(p),
            tag: StatusTag(
              icon: AppIcon.octagon,
              label: 'SOS',
              color: sosColour(p),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                    child: Semantics(
                      liveRegion: true,
                      container: true,
                      label: '${d.headline}. ${d.subline}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.headline,
                            style: TypeScale.hero.copyWith(color: p.text),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.subline,
                            style: TypeScale.body.copyWith(color: p.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                    child: _PositionBlock(position: view.position),
                  ),
                  const SizedBox(height: 8),
                  StatusChecklist(
                    rowHeight: 46,
                    rows: [
                      ChecklistRow(
                        icon: AppIcon.send,
                        label: switch (d.total) {
                          0 => 'SMS: nobody to message',
                          1 => 'SMS to 1 contact',
                          _ => 'SMS to ${d.total} contacts',
                        },
                        status: d.smsLabel,
                        state: d.smsState,
                      ),
                      if (d.beacon) ...[
                        const ChecklistRow(
                          icon: AppIcon.radar,
                          label: 'Beacon',
                          status: 'broadcasting',
                          state: RowState.live,
                        ),
                        ChecklistRow(
                          icon: AppIcon.people,
                          label: 'Group alerted',
                          status: groupDone
                              ? '${d.delivered} received'
                              : 'sending',
                          state: groupDone ? RowState.done : RowState.wait,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          ThumbPanel(
            children: [
              if (view.toolsAvailable) ...[
                Row(
                  children: [
                    Expanded(
                      child: LargeToggle(
                        icon: AppIcon.siren,
                        label: 'Siren',
                        value: view.siren,
                        onChanged: onSiren ?? (_) {},
                      ),
                    ),
                    SizedBox(width: prefs.space(10)),
                    Expanded(
                      child: LargeToggle(
                        icon: AppIcon.torch,
                        label: 'Torch strobe',
                        value: view.torch,
                        onChanged: onTorch ?? (_) {},
                      ),
                    ),
                  ],
                ),
                KeyButton(
                  icon: AppIcon.call,
                  label: 'Call 112',
                  sub: view.signal
                      ? null
                      : 'No signal. Enables when any signal appears.',
                  enabled: view.signal,
                  onPressed: onCall ?? noop,
                ),
              ],
              HoldButton.wide(
                label: 'Cancel SOS · hold 5 s',
                semanticsLabel: 'Cancel SOS, hold 5 seconds',
                icon: AppIcon.x,
                seconds: 5,
                color: sosColour(p),
                onComplete: onCancel ?? noop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The coordinates to read aloud, or "Waiting for GPS" without a fix.
class _PositionBlock extends StatelessWidget {
  const _PositionBlock({required this.position});

  final ShownPosition? position;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    final pos = position;
    if (pos == null) {
      return Semantics(
        container: true,
        label: 'Waiting for a GPS position',
        excludeSemantics: true,
        child: Text(
          'Waiting for GPS',
          style: TypeScale.display.copyWith(color: p.text2, height: 1.05),
        ),
      );
    }
    return Semantics(
      container: true,
      label: pos.spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pos.latText}\n${pos.lonText}',
            style: TypeScale.display.copyWith(color: p.text, height: 1.05),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: pos.altitudeText,
                  style: TypeScale.hero.copyWith(color: p.text),
                ),
                TextSpan(
                  text: ' m altitude',
                  style: TypeScale.body.copyWith(color: p.text2),
                ),
              ],
            ),
          ),
          Text(
            'position ±${pos.accuracyM.round()} m · ${pos.timeText}',
            style: TypeScale.caption.copyWith(color: p.text2),
          ),
        ],
      ),
    );
  }
}
