import 'package:engine_health/src/issues.dart';
import 'package:meta/meta.dart';

/// A snapshot of everything the watchdog looks at.
@immutable
class HealthInputs {
  /// Creates inputs.
  const HealthInputs({
    required this.now,
    required this.trekActive,
    required this.trekStartedAt,
    required this.lastFixAt,
    required this.locationPermission,
    required this.backgroundLocationPermission,
    required this.smsPermission,
    required this.batteryOptimizationExempt,
    required this.storageFreeMb,
    required this.batteryPercent,
  });

  /// Trusted time.
  final DateTime now;

  /// Whether a trek is running.
  final bool trekActive;

  /// When the trek began, if running.
  final DateTime? trekStartedAt;

  /// When the last accepted GPS fix arrived, if any.
  final DateTime? lastFixAt;

  /// Fine location permission.
  final bool locationPermission;

  /// Background location permission.
  final bool backgroundLocationPermission;

  /// SMS permission.
  final bool smsPermission;

  /// Exempt from battery optimisation.
  final bool batteryOptimizationExempt;

  /// Free storage in MB.
  final int storageFreeMb;

  /// Battery percent.
  final int batteryPercent;
}

/// Judges [HealthInputs] and lists what is wrong, most severe first.
class HealthWatchdog {
  /// Creates a watchdog.
  const HealthWatchdog({
    this.gpsStaleAfter = const Duration(minutes: 2),
    this.storageWarnMb = 100,
    this.batteryWarnPercent = 15,
  });

  /// How long without a fix counts as stale during a trek.
  final Duration gpsStaleAfter;

  /// Free storage below this warns.
  final int storageWarnMb;

  /// Battery below this warns.
  final int batteryWarnPercent;

  /// Everything wrong right now, critical first.
  List<HealthIssue> evaluate(HealthInputs i) {
    final issues = <HealthIssue>[
      if (i.trekActive) ..._gps(i),
      if (!i.locationPermission)
        const PermissionMissing('location', Severity.critical),
      if (!i.smsPermission) const PermissionMissing('sms', Severity.critical),
      if (!i.backgroundLocationPermission)
        const PermissionMissing('background location', Severity.warn),
      if (!i.batteryOptimizationExempt) const BatteryOptimised(),
      if (i.storageFreeMb < storageWarnMb) StorageLow(i.storageFreeMb),
      if (i.batteryPercent < batteryWarnPercent) BatteryLow(i.batteryPercent),
    ];
    // Stable: critical first, otherwise the order above.
    return [
      ...issues.where((e) => e.severity == Severity.critical),
      ...issues.where((e) => e.severity == Severity.warn),
    ];
  }

  List<HealthIssue> _gps(HealthInputs i) {
    final last = i.lastFixAt;
    if (last != null) {
      final age = i.now.difference(last);
      return age > gpsStaleAfter ? [GpsStale(age)] : const [];
    }
    final started = i.trekStartedAt;
    if (started != null && i.now.difference(started) > gpsStaleAfter) {
      return const [GpsStale(null)];
    }
    return const [];
  }
}
