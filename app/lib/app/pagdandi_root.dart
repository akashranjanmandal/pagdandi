import 'dart:async';

import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/app/screen_choice.dart';
import 'package:pagdandi_app/client/core_client.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/screens/active_trek_screen.dart';
import 'package:pagdandi_app/screens/basecamp_screen.dart';
import 'package:pagdandi_app/screens/contacts_screen.dart';
import 'package:pagdandi_app/screens/emergency_card_screen.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/screens/setup_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';
import 'package:pagdandi_app/screens/trek_actions.dart';

/// Chooses the screen from the app's state: Setup on a first run, Basecamp
/// before a trek, and whatever the core says during one. It sends the user's
/// choices to the core as commands; it never decides anything itself.
class PagdandiRoot extends StatefulWidget {
  /// Creates the root.
  const PagdandiRoot({
    required this.app,
    required this.client,
    required this.leftHanded,
    required this.onHand,
    super.key,
  });

  /// What the UI knows and does.
  final AppController app;

  /// The link to the core.
  final CoreClient client;

  /// Current handedness (display preference).
  final bool leftHanded;

  /// Handedness chosen in Setup (true = left).
  final ValueChanged<bool> onHand;

  @override
  State<PagdandiRoot> createState() => _PagdandiRootState();
}

class _PagdandiRootState extends State<PagdandiRoot>
    with WidgetsBindingObserver {
  Timer? _ticker;
  var _showCard = false;
  var _showContacts = false;
  var _lost = const LostView();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The fall countdown moves between messages from the core.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = widget.app.coreState?.state.emergency;
      final nav = widget.app.coreState?.nav;
      if (mounted && (s is FallCountdown || nav?.snoozedUntil != null)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have changed a permission in the system settings.
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.app.refreshPermissions());
    }
  }

  void _send(TrekEvent e) => unawaited(widget.client.send(e));

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (_showCard) {
          return EmergencyCardScreen(
            card: app.card,
            contacts: app.contacts,
            onSave: (c) => unawaited(app.saveCard(c)),
            onCall: app.toolsAvailable ? (n) => unawaited(app.call(n)) : null,
            onBack: () => setState(() => _showCard = false),
          );
        }
        if (_showContacts) {
          return ContactsScreen(
            contacts: app.contacts,
            onAdd: app.addContact,
            onRemove: (n) => unawaited(app.removeContact(n)),
            onDone: () => setState(() => _showContacts = false),
          );
        }
        switch (app.route) {
          case AppRoute.setup:
            return SetupScreen(
              contacts: app.contacts,
              name: app.name,
              leftHanded: app.leftHanded,
              readiness: app.readiness,
              initialStep: app.setupStep,
              batteryGuide: app.batteryGuide,
              onStep: (i) => unawaited(app.saveSetupStep(i)),
              onHand: (left) {
                unawaited(app.setLeftHanded(left: left));
                widget.onHand(left);
              },
              onName: (v) => unawaited(app.setName(v)),
              onAddContact: app.addContact,
              onRemoveContact: (n) => unawaited(app.removeContact(n)),
              onRequest: (p) async {
                final ok = await app.requestPermission(p);
                return ok;
              },
              onOpenSettings: () => unawaited(app.openSettings()),
              onFinish: () => unawaited(app.finishSetup()),
            );
          case AppRoute.basecamp:
            return BasecampScreen(
              readiness: app.readiness,
              onStart: () => unawaited(app.startTrek()),
              onFix: (item) => switch (item) {
                ReadyItem.contacts => setState(() => _showContacts = true),
                ReadyItem.card => setState(() => _showCard = true),
                _ => unawaited(app.fix(item)),
              },
              onEmergencyCard: () => setState(() => _showCard = true),
              routes: app.routeOptions,
              selectedRouteId: app.selectedRouteId,
              summary: app.routeSummary,
              onSelectRoute: (id) => unawaited(app.selectRoute(id)),
            );
          case AppRoute.trek:
            return _trek(app);
        }
      },
    );
  }

  Widget _trek(AppController app) {
    final m = app.coreState;
    if (m == null) return const SizedBox.shrink();
    final tools = app.toolsAvailable
        ? SosTools(
            siren: app.sirenOn,
            torch: app.torchOn,
            signal: app.signalAvailable,
          )
        : null;
    switch (chooseScreen(
      m,
      widget.client.sinceReceived,
      tools: tools,
      route: app.selectedRoute,
    )) {
      case TrekChoice(:final view):
        return ActiveTrekScreen(
          view: view,
          actions: TrekActions(
            onSosStarted: () => _send(const SosPressed()),
            onEndTrek: () => unawaited(app.endTrek()),
            onPin: () => unawaited(app.dropPin()),
            onSnooze: () => unawaited(app.snoozeAlerts()),
            onResumeAlerts: () => unawaited(app.resumeAlerts()),
            onReverseRoute: () => unawaited(app.reverseRoute()),
          ),
        );
      case SosChoice(:final view):
        return SosActiveScreen(
          view: view,
          onSiren: (on) => unawaited(app.setSiren(on: on)),
          onTorch: (on) => unawaited(app.setTorch(on: on)),
          onCall: () => unawaited(app.callEmergency()),
          onCancel: () => _send(const SosCancelled()),
        );
      case FallChoice(:final view):
        return FallCountdownScreen(
          view: view,
          onOk: () => _send(const FallCancelled()),
          onSendNow: () => _send(const SosPressed()),
        );
      case LostChoice(:final view):
        // The core's real data, with the stage of this screen's own flow.
        final shown = LostView(
          stage: _lost.stage,
          reason: _lost.reason,
          live: view.live,
          accuracy: view.accuracy,
          battery: view.battery,
        );
        return LostModeScreen(
          view: shown,
          onMove: () => setState(
            () =>
                _lost = LostView(stage: LostStage.prompt, reason: _lost.reason),
          ),
          onReason: (r) => setState(
            () => _lost = LostView(stage: LostStage.backtrack, reason: r),
          ),
          onStay: () => setState(() => _lost = const LostView()),
          onFound: () => _send(const FoundByGroup()),
        );
    }
  }
}
