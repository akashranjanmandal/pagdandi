import 'dart:convert';

import 'package:core_model/core_model.dart';
import 'package:engine_health/engine_health.dart';
import 'package:engine_navigation/engine_navigation.dart' show NavStatus;
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:meta/meta.dart';

const Map<String, TrekEvent> _commands = {
  'startTrek': StartTrek(),
  'endTrek': EndTrek(),
  'sosPressed': SosPressed(),
  'sosCancelled': SosCancelled(),
  'fallCancelled': FallCancelled(),
  'foundByGroup': FoundByGroup(),
  'friendSosAcknowledged': FriendSosAcknowledged(),
  'lostModeEntered': LostModeEntered(),
  'mapOpened': MapOpened(),
  'mapClosed': MapClosed(),
};

/// Encodes a user-originated event as a command for the core. Sensor and
/// network events (motion, falls, friend alerts) are the core's own and can
/// never be sent by the UI; passing one is a programming error.
String encodeCommand(TrekEvent e) {
  for (final entry in _commands.entries) {
    if (entry.value.runtimeType == e.runtimeType) {
      return jsonEncode({'c': entry.key});
    }
  }
  throw ArgumentError.value(e, 'e', 'not a UI command');
}

/// The command that turns route guidance around (walking home). It is not a
/// trek event: it changes only how the route is followed.
String encodeReverseRoute() => jsonEncode({'c': 'reverseRoute'});

/// Whether [json] is the reverse-route command.
bool isReverseRouteCommand(String json) {
  try {
    final raw = jsonDecode(json);
    return raw is Map<String, Object?> && raw['c'] == 'reverseRoute';
  } on FormatException {
    return false;
  }
}

/// The command that drops a pin at the current position. It is not a trek
/// event: it only saves a marker.
String encodeDropPin() => jsonEncode({'c': 'dropPin'});

/// Whether [json] is the drop-pin command.
bool isDropPinCommand(String json) {
  try {
    final raw = jsonDecode(json);
    return raw is Map<String, Object?> && raw['c'] == 'dropPin';
  } on FormatException {
    return false;
  }
}

/// Commands that change only how the route is followed. None is a trek event.
enum NavCommand {
  /// Walk the route the other way (home).
  reverseRoute,

  /// Silence off-route alerts for a while ("I know, exploring").
  snoozeAlerts,

  /// Bring the alerts back.
  resumeAlerts,
}

/// Encodes "silence off-route alerts for 10 minutes".
String encodeSnoozeAlerts() => jsonEncode({'c': 'snoozeAlerts'});

/// Encodes "bring the alerts back".
String encodeResumeAlerts() => jsonEncode({'c': 'resumeAlerts'});

/// The navigation command in [json], or null if it is anything else.
NavCommand? decodeNavCommand(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! Map<String, Object?>) return null;
    final c = raw['c'];
    for (final n in NavCommand.values) {
      if (n.name == c) return n;
    }
    return null;
  } on FormatException {
    return null;
  }
}

/// Decodes a command, or null if it is garbage or not a UI command. A forged
/// "fallSuspected" from outside decodes to null.
TrekEvent? decodeCommand(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! Map<String, Object?>) return null;
    final c = raw['c'];
    return c is String ? _commands[c] : null;
  } on FormatException {
    return null;
  }
}

/// A health issue as the UI shows it.
@immutable
class IssueView {
  /// Creates an issue view.
  const IssueView({
    required this.severity,
    required this.message,
    required this.fixHint,
  });

  /// Converts a watchdog issue.
  factory IssueView.from(HealthIssue i) => IssueView(
    severity: i.severity == Severity.critical ? 'critical' : 'warn',
    message: i.message,
    fixHint: i.fixHint,
  );

  /// `critical` or `warn`.
  final String severity;

  /// What is wrong.
  final String message;

  /// How to fix it.
  final String fixHint;
}

/// Everything the UI needs, published by the core after every change.
/// Where the walker is on the loaded route, as the UI needs it.
@immutable
class NavView {
  /// Creates the view.
  const NavView({
    required this.routeId,
    required this.routeName,
    required this.status,
    required this.progressM,
    required this.remainingM,
    required this.totalM,
    required this.crossTrackM,
    required this.bearingToGoDeg,
    required this.arrived,
    required this.reversed,
    required this.climbLeftM,
    this.headingDeg,
    this.nextName,
    this.nextDistM,
    this.reachedName,
    this.snoozedUntil,
  });

  /// Reads the JSON; throws when it is not a valid block.
  factory NavView.fromJson(Map<String, Object?> j) => NavView(
    routeId: j['id']! as String,
    routeName: j['name']! as String,
    status: NavStatus.values.byName(j['st']! as String),
    progressM: (j['p']! as num).toDouble(),
    remainingM: (j['r']! as num).toDouble(),
    totalM: (j['t']! as num).toDouble(),
    crossTrackM: (j['x']! as num).toDouble(),
    bearingToGoDeg: (j['b']! as num).toDouble(),
    headingDeg: (j['h'] as num?)?.toDouble(),
    arrived: j['ar']! as bool,
    reversed: j['rev']! as bool,
    climbLeftM: (j['cl']! as num).toDouble(),
    nextName: j['nn'] as String?,
    nextDistM: (j['nd'] as num?)?.toDouble(),
    reachedName: j['rn'] as String?,
    snoozedUntil: j['sn'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['sn']! as int, isUtc: true),
  );

  /// Which route.
  final String routeId;

  /// Its name.
  final String routeName;

  /// On route, off route, wrong way or GPS lost.
  final NavStatus status;

  /// Metres done.
  final double progressM;

  /// Metres left.
  final double remainingM;

  /// Route length.
  final double totalM;

  /// Metres from the trail.
  final double crossTrackM;

  /// Direction to walk, degrees from north.
  final double bearingToGoDeg;

  /// Direction the walker is facing or moving, if known.
  final double? headingDeg;

  /// At the end of the route.
  final bool arrived;

  /// Walking the route backwards (the way home).
  final bool reversed;

  /// Climb still to do, metres.
  final double climbLeftM;

  /// The next named place ahead.
  final String? nextName;

  /// Metres to it.
  final double? nextDistM;

  /// A place just reached (shown once).
  final String? reachedName;

  /// Off-route alerts are silenced until then (trusted time), or null.
  final DateTime? snoozedUntil;

  /// JSON for the channel.
  Map<String, Object?> toJson() => {
    'id': routeId,
    'name': routeName,
    'st': status.name,
    'p': progressM,
    'r': remainingM,
    't': totalM,
    'x': crossTrackM,
    'b': bearingToGoDeg,
    'h': headingDeg,
    'ar': arrived,
    'rev': reversed,
    'cl': climbLeftM,
    'nn': nextName,
    'nd': nextDistM,
    'rn': reachedName,
    'sn': snoozedUntil?.millisecondsSinceEpoch,
  };
}

/// Everything the core tells the UI about the trek, in one message.
@immutable
class CoreStateMessage {
  /// Creates a message.
  const CoreStateMessage({
    required this.state,
    required this.sos,
    required this.issues,
    required this.stats,
    required this.battery,
    required this.fix,
    required this.at,
    this.nav,
    this.pinCount = 0,
  });

  /// The trek statechart state.
  final TrekState state;

  /// SOS delivery progress.
  final SosSummary sos;

  /// Health issues, most severe first.
  final List<IssueView> issues;

  /// Distance, climb, time, altitude.
  final TrekStats stats;

  /// Battery percent.
  final int battery;

  /// Latest accepted fix, if any.
  final LocationFix? fix;

  /// When the message was made (trusted time).
  final DateTime at;

  /// Route guidance, or null on a free trek.
  final NavView? nav;

  /// Pins dropped on this trek.
  final int pinCount;

  /// JSON for the channel.
  String encode() => jsonEncode({
    'v': 1,
    'state': encodeSnapshot(state),
    'sos': {
      'active': sos.active,
      'total': sos.total,
      'queued': sos.queued,
      'sending': sos.sending,
      'sent': sos.sent,
      'delivered': sos.delivered,
      'failed': sos.failed,
      'cancelled': sos.cancelled,
    },
    'issues': [
      for (final i in issues) {'s': i.severity, 'm': i.message, 'f': i.fixHint},
    ],
    'stats': {
      'd': stats.distanceM,
      'c': stats.climbM,
      'e': stats.elapsed.inSeconds,
      'a': stats.altitudeM,
    },
    'battery': battery,
    'fix': fix == null
        ? null
        : {
            'lat': fix!.latitude,
            'lon': fix!.longitude,
            'acc': fix!.accuracyM,
            'alt': fix!.altitudeM,
            'spd': fix!.speedMps,
            'brg': fix!.bearingDeg,
            't': fix!.gpsTime.millisecondsSinceEpoch,
          },
    'at': at.millisecondsSinceEpoch,
    'nav': nav?.toJson(),
    'pins': pinCount,
  });

  /// Reads a message, or null if damaged or from a newer version.
  static CoreStateMessage? decode(String json) {
    try {
      final m = jsonDecode(json);
      if (m is! Map<String, Object?> || m['v'] != 1) return null;
      final state = m['state'];
      final sos = m['sos'];
      final issues = m['issues'];
      final stats = m['stats'];
      final battery = m['battery'];
      final at = m['at'];
      if (state is! String ||
          sos is! Map<String, Object?> ||
          issues is! List<Object?> ||
          stats is! Map<String, Object?> ||
          battery is! int ||
          at is! int) {
        return null;
      }
      final s = decodeSnapshot(state);
      if (s == null) return null;
      int n(String k) => sos[k]! as int;
      final fix = m['fix'];
      return CoreStateMessage(
        state: s,
        sos: SosSummary(
          active: sos['active']! as bool,
          total: n('total'),
          queued: n('queued'),
          sending: n('sending'),
          sent: n('sent'),
          delivered: n('delivered'),
          failed: n('failed'),
          cancelled: n('cancelled'),
        ),
        issues: [
          for (final i in issues.cast<Map<String, Object?>>())
            IssueView(
              severity: i['s']! as String,
              message: i['m']! as String,
              fixHint: i['f']! as String,
            ),
        ],
        stats: TrekStats(
          distanceM: (stats['d']! as num).toDouble(),
          climbM: (stats['c']! as num).toDouble(),
          elapsed: Duration(seconds: stats['e']! as int),
          altitudeM: (stats['a'] as num?)?.toDouble(),
        ),
        battery: battery,
        fix: fix == null ? null : _fix(fix as Map<String, Object?>),
        at: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
        pinCount: (m['pins'] as int?) ?? 0,
        nav: m['nav'] == null
            ? null
            : NavView.fromJson(m['nav']! as Map<String, Object?>),
      );
    } on Object {
      return null;
    }
  }

  static LocationFix _fix(Map<String, Object?> f) => LocationFix(
    latitude: (f['lat']! as num).toDouble(),
    longitude: (f['lon']! as num).toDouble(),
    accuracyM: (f['acc']! as num).toDouble(),
    gpsTime: DateTime.fromMillisecondsSinceEpoch(f['t']! as int, isUtc: true),
    altitudeM: (f['alt'] as num?)?.toDouble(),
    speedMps: (f['spd'] as num?)?.toDouble(),
    bearingDeg: (f['brg'] as num?)?.toDouble(),
  );
}
