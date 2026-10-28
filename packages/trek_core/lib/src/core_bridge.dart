import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_health/engine_health.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:trek_core/src/navigation_controller.dart';
import 'package:trek_core/src/protocol.dart';
import 'package:trek_core/src/trek_runtime.dart';

/// The core's end of the UI/core channel: applies UI commands to the runtime
/// and publishes the full state after every change. Bursts of changes in one
/// turn are published once. A failing channel is logged and never stops the
/// core.
class CoreBridge {
  /// Creates the bridge.
  CoreBridge({
    required this.runtime,
    required this.channel,
    required this.tracking,
    required this.health,
    required this.battery,
    required this.clock,
    required this.logger,
    this.beforeCommand,
    this.navigation,
    this.onDropPin,
    this.pinCount,
  });

  /// The runtime driven by commands.
  final TrekRuntime runtime;

  /// The channel to the UI.
  final CoreChannel channel;

  /// Source of breadcrumb, position and stats.
  final TrackingPipeline tracking;

  /// Health issues.
  final HealthMonitor health;

  /// Battery.
  final BatteryMonitor battery;

  /// Trusted time for message stamps.
  final TrustedClock clock;

  /// Log.
  final Logger logger;

  /// Route guidance included in every message, if a route is loaded.
  final NavigationController? navigation;

  /// Called when the UI asks to drop a pin at the current position.
  final Future<void> Function()? onDropPin;

  /// Pins dropped on this trek, shown in every message.
  final int Function()? pinCount;

  /// Runs before an SOS or a trek start is dispatched, so the latest settings
  /// (contacts, name) are in force. A failure never stops the command.
  final Future<void> Function()? beforeCommand;

  static const _tag = 'bridge';

  final _subs = <StreamSubscription<Object?>>[];
  bool _scheduled = false;
  bool _disposed = false;

  /// Starts listening and publishes the current state.
  Future<void> start() async {
    _subs
      ..add(channel.commands.listen((c) => unawaited(_onCommand(c))))
      ..add(runtime.states.listen(_changed))
      ..add(runtime.sosSummary.listen(_changed))
      ..add(tracking.accepted.listen(_changed))
      ..add(health.changes.listen(_changed))
      ..add(battery.changes.listen(_changed));
    final nav = navigation;
    if (nav != null) _subs.add(nav.changes.listen(_changed));
    await _publish();
  }

  /// Feeds fresh health inputs to the watchdog; changes are published.
  void updateHealth(HealthInputs inputs) => health.check(inputs);

  /// Publishes the current state again (something outside the bridge changed,
  /// such as a pin being saved).
  void refresh() => _changed(null);

  /// Stops listening and publishing.
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }

  void _changed(Object? _) {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      unawaited(_publish());
    });
  }

  Future<void> _onCommand(String json) async {
    if (isDropPinCommand(json)) {
      try {
        await onDropPin?.call();
      } on Object catch (e) {
        logger.error(_tag, 'could not drop a pin', error: e);
      }
      return;
    }
    final navCommand = decodeNavCommand(json);
    if (navCommand != null) {
      switch (navCommand) {
        case NavCommand.reverseRoute:
          navigation?.reverse();
        case NavCommand.snoozeAlerts:
          navigation?.snooze(const Duration(minutes: 10));
        case NavCommand.resumeAlerts:
          navigation?.resumeAlerts();
      }
      return;
    }
    final event = decodeCommand(json);
    if (event == null) {
      logger.warn(_tag, 'ignored a command that is not a UI command');
      return;
    }
    try {
      if (event is SosPressed || event is StartTrek) {
        try {
          await beforeCommand?.call();
        } on Object catch (e) {
          logger.warn(
            _tag,
            'could not refresh settings, using the last',
            error: e,
          );
        }
      }
      await runtime.dispatch(event);
    } on Object catch (e) {
      logger.error(_tag, 'command failed', error: e);
    }
  }

  CoreStateMessage _message() {
    final crumb = tracking.breadcrumb;
    return CoreStateMessage(
      state: runtime.state,
      sos: runtime.sosCurrent,
      issues: [for (final i in health.current) IssueView.from(i)],
      stats: computeStats(crumb),
      battery: battery.level,
      fix: crumb.isEmpty ? null : crumb.last,
      at: clock.now().time,
      nav: navigation?.view,
      pinCount: pinCount?.call() ?? 0,
    );
  }

  Future<void> _publish() async {
    if (_disposed) return;
    try {
      await channel.publish(_message().encode());
    } on Object catch (e) {
      logger.warn(_tag, 'publish failed, next change will retry', error: e);
    }
  }
}
