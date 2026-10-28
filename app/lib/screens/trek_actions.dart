import 'package:flutter/foundation.dart';

/// What the UI can ask the trek core to do. The UI only sends these; it never
/// decides. The default no-ops let screens render before the core is wired.
class TrekActions {
  /// Creates actions; every callback defaults to doing nothing.
  const TrekActions({
    this.onSosHoldTick = _noInt,
    this.onSosStarted = _no,
    this.onPin = _no,
    this.onOpenRadar = _no,
    this.onTalkStart = _no,
    this.onTalkEnd = _no,
    this.onSnooze = _no,
    this.onResumeAlerts = _no,
    this.onEndTrek = _no,
    this.onReverseRoute = _no,
  });

  /// Each second of the SOS hold (haptic tick).
  final void Function(int second) onSosHoldTick;

  /// The SOS hold completed.
  final VoidCallback onSosStarted;

  /// Drop a pin.
  final VoidCallback onPin;

  /// Open the group radar.
  final VoidCallback onOpenRadar;

  /// Push-to-talk pressed.
  final VoidCallback onTalkStart;

  /// Push-to-talk released.
  final VoidCallback onTalkEnd;

  /// Snooze off-route alerts for 10 minutes.
  final VoidCallback onSnooze;

  /// Resume snoozed alerts.
  final VoidCallback onResumeAlerts;

  /// The End trek hold completed (live trek only).
  final VoidCallback onEndTrek;

  /// "I'm heading back": follow the route the other way.
  final VoidCallback onReverseRoute;
}

void _no() {}
void _noInt(int _) {}
