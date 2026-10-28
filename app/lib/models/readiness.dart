import 'package:meta/meta.dart';

/// What a readiness row is about.
enum ReadyItem {
  /// Emergency contacts.
  contacts,

  /// Location permission.
  location,

  /// SMS permission.
  sms,

  /// Notification permission.
  notifications,

  /// Background (always-on) location.
  background,

  /// Emergency card filled in.
  card,
}

/// How a readiness row stands.
enum ReadyStatus {
  /// Fine.
  ok,

  /// Missing but does not stop an SOS from working.
  warn,

  /// Missing and an SOS could not work.
  critical,
}

/// One row on the Basecamp screen.
@immutable
class ReadyRow {
  /// Creates a row.
  const ReadyRow({
    required this.id,
    required this.label,
    required this.status,
    required this.stateText,
  });

  /// What it is about.
  final ReadyItem id;

  /// Short name.
  final String label;

  /// Where it stands.
  final ReadyStatus status;

  /// The state in words (never colour alone).
  final String stateText;
}

/// Whether the phone is ready for a trek, and why not.
/// Critical = contacts, location, SMS. Everything else only warns.
@immutable
class Readiness {
  /// Creates the readiness from what is known now.
  const Readiness({
    required this.contactCount,
    required this.location,
    required this.sms,
    required this.notifications,
    required this.backgroundLocation,
    required this.cardFilled,
    required this.trekRunning,
  });

  /// Emergency contacts saved.
  final int contactCount;

  /// Location permission granted.
  final bool location;

  /// SMS permission granted.
  final bool sms;

  /// Notification permission granted.
  final bool notifications;

  /// Background location granted.
  final bool backgroundLocation;

  /// Emergency card has content.
  final bool cardFilled;

  /// A trek is already running.
  final bool trekRunning;

  /// Rows, worst first.
  List<ReadyRow> get rows {
    ReadyRow row(
      ReadyItem id,
      String label,
      // A private local helper; named booleans would only add noise.
      // ignore: avoid_positional_boolean_parameters
      bool ok,
      ReadyStatus bad,
      String okText,
      String badText,
    ) => ReadyRow(
      id: id,
      label: label,
      status: ok ? ReadyStatus.ok : bad,
      stateText: ok ? okText : badText,
    );
    final all = [
      row(
        ReadyItem.contacts,
        'Emergency contacts',
        contactCount > 0,
        ReadyStatus.critical,
        '$contactCount added',
        'none added',
      ),
      row(
        ReadyItem.location,
        'Location',
        location,
        ReadyStatus.critical,
        'allowed',
        'not allowed',
      ),
      row(
        ReadyItem.sms,
        'Send SMS',
        sms,
        ReadyStatus.critical,
        'allowed',
        'not allowed',
      ),
      row(
        ReadyItem.notifications,
        'Notifications',
        notifications,
        ReadyStatus.warn,
        'allowed',
        'off',
      ),
      row(
        ReadyItem.background,
        'Location when screen is off',
        backgroundLocation,
        ReadyStatus.warn,
        'allowed',
        'not confirmed',
      ),
      row(
        ReadyItem.card,
        'Emergency card',
        cardFilled,
        ReadyStatus.warn,
        'filled in',
        'empty',
      ),
    ];
    // Stable sort: critical, then warn, then ok; ties keep their order.
    int rank(ReadyRow r) => switch (r.status) {
      ReadyStatus.critical => 0,
      ReadyStatus.warn => 1,
      ReadyStatus.ok => 2,
    };
    final indexed = all.asMap().entries.toList()
      ..sort((a, b) {
        final c = rank(a.value).compareTo(rank(b.value));
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  int get _criticalCount =>
      rows.where((r) => r.status == ReadyStatus.critical).length;

  /// Whether Start trek may be pressed.
  bool get canStart => !trekRunning && _criticalCount == 0;

  /// Show "Open trek" instead of "Start trek".
  bool get showOpenTrek => trekRunning;

  /// Why Start is disabled, or null when it is not.
  String? get blockedReason {
    if (trekRunning || _criticalCount == 0) return null;
    final n = _criticalCount;
    return 'Fix $n ${n == 1 ? 'thing' : 'things'} first';
  }
}
