import 'package:meta/meta.dart';

/// How serious a health issue is.
enum Severity {
  /// Safety is compromised now (e.g. an SOS could not be sent).
  critical,

  /// Something to fix soon.
  warn,
}

/// Something wrong with the phone that could make the app fail the user.
/// Wording is plain and calm: what is wrong, then how to fix it.
@immutable
sealed class HealthIssue {
  const HealthIssue();

  /// How serious it is.
  Severity get severity;

  /// What is wrong.
  String get message;

  /// What to do about it.
  String get fixHint;

  /// Values that define equality.
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      other is HealthIssue &&
      other.runtimeType == runtimeType &&
      _same(other.props, props);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(props));

  static bool _same(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// No usable GPS fix for too long during a trek.
final class GpsStale extends HealthIssue {
  /// Creates the issue; [age] is null when there has been no fix at all.
  const GpsStale(this.age);

  /// Time since the last fix, or null if none yet.
  final Duration? age;

  @override
  Severity get severity => Severity.warn;

  @override
  String get message =>
      age == null ? 'No GPS fix yet' : 'No GPS fix for ${age!.inMinutes} min';

  @override
  String get fixHint => 'Move to open sky and check that location is on';

  @override
  List<Object?> get props => [age];
}

/// A permission the app needs is off.
final class PermissionMissing extends HealthIssue {
  /// Creates the issue.
  const PermissionMissing(this.permission, this.severity);

  /// Plain name: location, sms, background location.
  final String permission;

  @override
  final Severity severity;

  @override
  String get message => 'The $permission permission is off';

  @override
  String get fixHint => 'Allow $permission in Settings, Apps, Pagdandi';

  @override
  List<Object?> get props => [permission, severity];
}

/// Battery optimisation may stop the app in the background.
final class BatteryOptimised extends HealthIssue {
  /// Creates the issue.
  const BatteryOptimised();

  @override
  Severity get severity => Severity.warn;

  @override
  String get message => 'Battery saver may stop Pagdandi in the background';

  @override
  String get fixHint => 'Turn off battery optimisation for Pagdandi';

  @override
  List<Object?> get props => const [];
}

/// Little free storage.
final class StorageLow extends HealthIssue {
  /// Creates the issue.
  const StorageLow(this.freeMb);

  /// Free storage in megabytes.
  final int freeMb;

  @override
  Severity get severity => freeMb < 20 ? Severity.critical : Severity.warn;

  @override
  String get message => 'Only $freeMb MB of storage left';

  @override
  String get fixHint => 'Free some space so the trek log can be saved';

  @override
  List<Object?> get props => [freeMb];
}

/// Low battery.
final class BatteryLow extends HealthIssue {
  /// Creates the issue.
  const BatteryLow(this.percent);

  /// Battery percent.
  final int percent;

  @override
  Severity get severity => percent < 5 ? Severity.critical : Severity.warn;

  @override
  String get message => 'Battery at $percent%';

  @override
  String get fixHint => 'Switch to Saver mode and keep the phone warm';

  @override
  List<Object?> get props => [percent];
}
