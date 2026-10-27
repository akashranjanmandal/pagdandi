import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/motion.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/screens/active_trek_screen.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/friend_sos_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';
import 'package:pagdandi_app/screens/trek_actions.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';

/// Pushes [screen] with a crossfade.
Future<void> openScreen(BuildContext context, Widget screen) =>
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: Motion.slow,
        reverseTransitionDuration: Motion.base,
        pageBuilder: (context, _, _) => screen,
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Motion.enter),
          child: child,
        ),
      ),
    );

/// Interactive Active Trek: SOS hold opens the SOS screen, snooze and PTT work.
class ActiveTrekPreview extends StatefulWidget {
  /// Creates the preview.
  const ActiveTrekPreview({
    required this.nav,
    this.stationary = false,
    this.toast,
    this.snoozed = false,
    super.key,
  });

  /// Navigation state to show.
  final NavState nav;

  /// Standing still.
  final bool stationary;

  /// Received message to show.
  final ToastMessage? toast;

  /// Start with off-route alerts snoozed.
  final bool snoozed;

  @override
  State<ActiveTrekPreview> createState() => _ActiveTrekPreviewState();
}

class _ActiveTrekPreviewState extends State<ActiveTrekPreview> {
  PttState _ptt = PttState.idle;
  late Duration? _snooze = widget.snoozed ? const Duration(minutes: 10) : null;

  @override
  Widget build(BuildContext context) => ActiveTrekScreen(
    view: ActiveTrekView.sample(
      widget.nav,
      stationary: widget.stationary,
      toast: widget.toast,
      snoozeLeft: _snooze,
      ptt: _ptt,
    ),
    actions: TrekActions(
      onSosStarted: () => openScreen(context, const SosPreview()),
      onSnooze: () => setState(() => _snooze = const Duration(minutes: 10)),
      onResumeAlerts: () => setState(() => _snooze = null),
      onTalkStart: () => setState(() => _ptt = PttState.talking),
      onTalkEnd: () => setState(() => _ptt = PttState.idle),
    ),
  );
}

/// Active Trek with a fixed PTT state (to look at receiving and busy).
class PttStatePreview extends StatelessWidget {
  /// Creates the preview.
  const PttStatePreview({required this.state, super.key});

  /// PTT state to show.
  final PttState state;

  @override
  Widget build(BuildContext context) => ActiveTrekScreen(
    view: ActiveTrekView.sample(NavState.onRoute, ptt: state),
  );
}

/// Interactive lost mode: reason prompt, backtrack, found.
class LostPreview extends StatefulWidget {
  /// Creates the preview.
  const LostPreview({
    this.stage = LostStage.lost,
    this.groupReached = false,
    super.key,
  });

  /// Starting stage.
  final LostStage stage;

  /// Whether the group has been reached.
  final bool groupReached;

  @override
  State<LostPreview> createState() => _LostPreviewState();
}

class _LostPreviewState extends State<LostPreview> {
  late LostView _v = LostView(
    stage: widget.stage,
    groupReached: widget.groupReached,
  );

  @override
  Widget build(BuildContext context) => LostModeScreen(
    view: _v,
    onMove: () => setState(
      () => _v = LostView(
        stage: LostStage.prompt,
        groupReached: _v.groupReached,
        torch: _v.torch,
        siren: _v.siren,
      ),
    ),
    onReason: (r) => setState(
      () => _v = LostView(
        stage: LostStage.backtrack,
        reason: r,
        groupReached: _v.groupReached,
      ),
    ),
    onStay: () => setState(
      () => _v = LostView(
        groupReached: _v.groupReached,
        torch: _v.torch,
        siren: _v.siren,
      ),
    ),
    onFound: () => setState(
      () =>
          _v = LostView(stage: LostStage.found, groupReached: _v.groupReached),
    ),
    onTorch: (v) => setState(
      () => _v = LostView(
        stage: _v.stage,
        reason: _v.reason,
        groupReached: _v.groupReached,
        torch: v,
        siren: _v.siren,
      ),
    ),
    onSiren: (v) => setState(
      () => _v = LostView(
        stage: _v.stage,
        reason: _v.reason,
        groupReached: _v.groupReached,
        torch: _v.torch,
        siren: v,
      ),
    ),
    onBackToTrek: () => Navigator.of(context).pop(),
  );
}

/// Interactive friend alert: guide, card, call.
class FriendPreview extends StatefulWidget {
  /// Creates the preview.
  const FriendPreview({
    this.kind = FriendKind.sentSos,
    this.signal = false,
    super.key,
  });

  /// Alert kind.
  final FriendKind kind;

  /// Whether a signal exists.
  final bool signal;

  @override
  State<FriendPreview> createState() => _FriendPreviewState();
}

class _FriendPreviewState extends State<FriendPreview> {
  late FriendKind _kind = widget.kind;
  bool _card = false;

  @override
  Widget build(BuildContext context) => FriendSosScreen(
    view: FriendSosView(kind: _kind, signal: widget.signal, cardOpen: _card),
    onGuide: () => setState(() => _kind = FriendKind.guiding),
    onCard: () => setState(() => _card = true),
    onCloseCard: () => setState(() => _card = false),
    onBackToTrek: () => Navigator.of(context).pop(),
  );
}

/// Interactive fall countdown running in real time.
class FallPreview extends StatefulWidget {
  /// Creates the preview.
  const FallPreview({this.start = 60, super.key});

  /// Seconds to start from.
  final int start;

  @override
  State<FallPreview> createState() => _FallPreviewState();
}

class _FallPreviewState extends State<FallPreview> {
  late int _left = widget.start;
  FallStage _stage = FallStage.running;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        _finish(FallStage.sent);
      } else {
        setState(() => _left--);
      }
    });
  }

  void _finish(FallStage s) {
    _timer?.cancel();
    setState(() => _stage = s);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FallCountdownScreen(
    view: FallView(stage: _stage, secondsLeft: _left),
    onOk: () => _finish(FallStage.cancelled),
    onSendNow: () => _finish(FallStage.sent),
    onOpenSos: () => openScreen(context, const SosPreview()),
    onBackToTrek: () => Navigator.of(context).pop(),
  );
}

/// Interactive SOS screen: siren, torch, cancel.
class SosPreview extends StatefulWidget {
  /// Creates the preview.
  const SosPreview({
    this.delivered = 0,
    this.signal = false,
    this.cancelled = false,
    super.key,
  });

  /// Contacts reached, of 3.
  final int delivered;

  /// Whether a signal exists.
  final bool signal;

  /// Start cancelled.
  final bool cancelled;

  @override
  State<SosPreview> createState() => _SosPreviewState();
}

class _SosPreviewState extends State<SosPreview> {
  bool _siren = false;
  bool _torch = false;
  late bool _cancelled = widget.cancelled;

  @override
  Widget build(BuildContext context) => SosActiveScreen(
    view: SosView(
      delivery: SosDelivery(total: 3, delivered: widget.delivered),
      signal: widget.signal,
      siren: _siren,
      torch: _torch,
      cancelled: _cancelled,
    ),
    onSiren: (v) => setState(() => _siren = v),
    onTorch: (v) => setState(() => _torch = v),
    onCancel: () => setState(() => _cancelled = true),
    onBackToTrek: () => Navigator.of(context).popUntil((r) => r.isFirst),
  );
}
