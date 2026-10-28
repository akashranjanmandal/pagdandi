import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:meta/meta.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/widgets/group_row.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';
import 'package:pagdandi_app/widgets/stat_triplet.dart';
import 'package:trek_core/trek_core.dart';

/// A received quick message.
@immutable
class ToastMessage {
  /// Creates a message.
  const ToastMessage(this.sender, this.text);

  /// Who sent it.
  final String sender;

  /// What it says.
  final String text;
}

/// Everything the Active Trek screen shows, as one immutable snapshot.
/// (The real snapshot will come from TrekState; this is the UI's view of it.)
@immutable
class ActiveTrekView {
  /// Creates a view.
  const ActiveTrekView({
    required this.nav,
    required this.hero,
    required this.sub,
    required this.dialAngle,
    required this.accuracy,
    required this.battery,
    required this.stats,
    required this.altitude,
    required this.groupMain,
    required this.groupFact,
    required this.groupTone,
    this.stationary = false,
    this.toast,
    this.snoozeLeft,
    this.pinCount = 0,
    this.ptt = PttState.idle,
    this.uncertaintyRadius = 14,
    this.statsHeader = 'to camp',
    this.live = false,
    this.position,
    this.alert,
    this.route,
    this.navView,
    this.me,
  });

  /// The view of a real trek from the core's state. No route is loaded in
  /// this build, so it is a free trek: distance walked, honest GPS status.
  factory ActiveTrekView.fromCore(
    CoreStateMessage m, {
    Route? route,
    Duration sinceReceived = Duration.zero,
  }) {
    final fix = m.fix;
    final nv = m.nav;
    if (route != null) return _onRoute(m, route, nv, sinceReceived);
    final km = m.stats.distanceM >= 1000;
    final distance = km
        ? Stat(
            value: (m.stats.distanceM / 1000).toStringAsFixed(1),
            unit: 'km',
            caption: 'distance',
          )
        : Stat(
            value: m.stats.distanceM.round().toString(),
            unit: 'm',
            caption: 'distance',
          );
    final e = m.stats.elapsed;
    final time =
        '${e.inHours}:${(e.inMinutes % 60).toString().padLeft(2, '0')}';
    final alt = fix?.altitudeM;
    return ActiveTrekView(
      nav: fix == null ? NavState.gpsLost : NavState.free,
      hero: fix == null
          ? 'Waiting for GPS'
          : '${distance.value} ${distance.unit}',
      sub: fix == null
          ? 'keep to the trail you know'
          : 'walked so far · no route loaded',
      dialAngle: 0,
      accuracy: fix == null ? 'GPS ±—' : 'GPS ±${fix.accuracyM.round()} m',
      battery: m.battery,
      stats: [
        distance,
        Stat(
          value: m.stats.climbM.round().toString(),
          unit: 'm',
          caption: 'climb',
        ),
        Stat(value: time, unit: 'h', caption: 'time'),
      ],
      altitude: alt == null ? '—' : '${_thousands(alt.round())} m',
      groupMain: 'Solo',
      groupFact: 'no group in this trek',
      groupTone: GroupTone.ok,
      stationary: m.state.activity == Activity.stationary,
      statsHeader: 'so far',
      live: true,
      pinCount: m.pinCount,
      alert: _alert(m.issues),
      position: fix == null ? null : _position(fix.latitude, fix.longitude),
    );
  }

  /// The sample trek, in the given navigation state (docs/design copy).
  factory ActiveTrekView.sample(
    NavState nav, {
    bool stationary = false,
    ToastMessage? toast,
    Duration? snoozeLeft,
    PttState ptt = PttState.idle,
  }) {
    final c = switch (nav) {
      NavState.onRoute => ('1.4 km', 'to Kalipokhri · stay on ridge', 0.0),
      NavState.junction => (
        'Fork in 80 m',
        'keep left · path going uphill',
        -35.0,
      ),
      NavState.offRoute => (
        '42 m off trail',
        'turn back · trail is to your left',
        -125.0,
      ),
      NavState.wrongWay => (
        'Heading back to start',
        'turn around to continue',
        180.0,
      ),
      NavState.gpsLost => (
        'GPS signal weak',
        'last fix 2 min ago · keep to the trail',
        0.0,
      ),
      NavState.regroup => (
        'Rahul · 210 m',
        'last seen 3 min ago · downhill',
        160.0,
      ),
      NavState.free => ('2.4 km', 'walked so far · no route loaded', 0.0),
    };
    final regroup = nav == NavState.regroup;
    return ActiveTrekView(
      nav: nav,
      hero: c.$1,
      sub: c.$2,
      dialAngle: c.$3,
      accuracy: nav == NavState.gpsLost ? 'GPS ±—' : 'GPS ±6 m',
      battery: 78,
      stats: const [
        Stat(value: '6.2', unit: 'km', caption: 'distance'),
        Stat(value: '320', unit: 'm', caption: 'climb'),
        Stat(value: '2:10', unit: 'h', caption: 'time'),
      ],
      altitude: nav == NavState.offRoute ? '3,209 m' : '3,214 m',
      groupMain: regroup ? 'Regrouping' : '4 of 4 in range',
      groupFact: regroup
          ? 'Rahul · 210 m'
          : nav == NavState.gpsLost
          ? 'distances paused · GPS lost'
          : 'Rahul 60 m behind',
      groupTone: regroup
          ? GroupTone.regroup
          : nav == NavState.gpsLost
          ? GroupTone.warn
          : GroupTone.ok,
      stationary: stationary,
      toast: toast,
      snoozeLeft: snoozeLeft,
      ptt: ptt,
    );
  }

  /// Navigation state.
  final NavState nav;

  /// Main instruction.
  final String hero;

  /// Line under it.
  final String sub;

  /// Dial direction in degrees.
  final double dialAngle;

  /// "GPS ±6 m".
  final String accuracy;

  /// Battery percent.
  final int battery;

  /// The three "to camp" numbers.
  final List<Stat> stats;

  /// Altitude caption.
  final String altitude;

  /// Group bar count text.
  final String groupMain;

  /// Group bar most important fact.
  final String groupFact;

  /// Group bar colouring.
  final GroupTone groupTone;

  /// Standing still: numbers dim and a paused line shows.
  final bool stationary;

  /// Received quick message, if any.
  final ToastMessage? toast;

  /// Time left on an off-route snooze, or null when not snoozed.
  final Duration? snoozeLeft;

  /// Pins dropped on this trek.
  final int pinCount;

  /// Push-to-talk state.
  final PttState ptt;

  /// Radius of the GPS-lost uncertainty circle.
  final double uncertaintyRadius;

  /// Whether this is the real trek (from the core) and not the design sample.
  /// Live views never show sample friends, map or push-to-talk.
  final bool live;

  /// The worst critical health issue ("The sms permission is off · Allow
  /// sms"), or null. Warnings never interrupt the trek screen.
  final String? alert;

  /// The route being followed, for the map panel.
  final Route? route;

  /// Where the walker is on it, from the core.
  final NavView? navView;

  /// The last position, for the map panel.
  final GeoPoint? me;

  /// "27.0000° N  88.0000° E" of the last fix, or null without one.
  final String? position;

  /// Heading of the numbers: "to camp" on a route, "so far" on a free trek.
  final String statsHeader;

  static String _short(String name) =>
      name.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '').trim();

  static (String, String) _dist(double m) => m >= 1000
      ? ((m / 1000).toStringAsFixed(1), 'km')
      : (m.round().toString(), 'm');

  static const _compass = [
    'north',
    'north-east',
    'east',
    'south-east',
    'south',
    'south-west',
    'west',
    'north-west',
  ];

  static String _compassName(double deg) =>
      _compass[((deg % 360) / 45).round() % 8];

  static ActiveTrekView _onRoute(
    CoreStateMessage m,
    Route route,
    NavView? nv,
    Duration sinceReceived,
  ) {
    final fix = m.fix;
    final end = route.checkpoints.isEmpty
        ? route.name
        : route.checkpoints.last.name;
    final e = m.stats.elapsed;
    final time =
        '${e.inHours}:${(e.inMinutes % 60).toString().padLeft(2, '0')}';
    final alt = fix?.altitudeM;
    Duration? snooze;
    final until = nv?.snoozedUntil;
    if (until != null) {
      final left = until.difference(m.at) - sinceReceived;
      if (!left.isNegative && left > Duration.zero) snooze = left;
    }
    final common = (
      accuracy: fix == null ? 'GPS ±—' : 'GPS ±${fix.accuracyM.round()} m',
      altitude: alt == null ? '—' : '${_thousands(alt.round())} m',
      position: fix == null ? null : _position(fix.latitude, fix.longitude),
      me: fix == null ? null : GeoPoint(fix.latitude, fix.longitude),
    );
    ActiveTrekView make({
      required NavState nav,
      required String hero,
      required String sub,
      required double dial,
      List<Stat>? stats,
      String? header,
    }) => ActiveTrekView(
      nav: nav,
      hero: hero,
      sub: sub,
      dialAngle: dial,
      accuracy: common.accuracy,
      battery: m.battery,
      stats:
          stats ??
          [
            for (final (v, u, c) in [
              (
                _dist(m.stats.distanceM).$1,
                _dist(m.stats.distanceM).$2,
                'distance',
              ),
              (m.stats.climbM.round().toString(), 'm', 'climb'),
              (time, 'h', 'time'),
            ])
              Stat(value: v, unit: u, caption: c),
          ],
      altitude: common.altitude,
      groupMain: 'Solo',
      groupFact: 'no group in this trek',
      groupTone: GroupTone.ok,
      stationary: m.state.activity == Activity.stationary,
      statsHeader: header ?? 'so far',
      live: true,
      position: common.position,
      alert: _alert(m.issues),
      route: route,
      navView: nv,
      me: common.me,
      snoozeLeft: snooze,
      pinCount: m.pinCount,
    );

    if (nv == null) {
      return make(
        nav: NavState.gpsLost,
        hero: 'Waiting for GPS',
        sub: '${route.name} · waiting for a position',
        dial: 0,
      );
    }
    final heading = nv.headingDeg;
    final dial = heading == null
        ? nv.bearingToGoDeg
        : angleDiffDeg(heading, nv.bearingToGoDeg);
    final left = _dist(nv.remainingM);
    final stats = [
      Stat(value: left.$1, unit: left.$2, caption: 'left'),
      Stat(
        value: nv.climbLeftM.round().toString(),
        unit: 'm',
        caption: 'climb left',
      ),
      Stat(value: time, unit: 'h', caption: 'time'),
    ];
    final header = 'to ${_short(end)}';

    ActiveTrekView state(NavState n, String hero, String sub) => make(
      nav: n,
      hero: hero,
      sub: sub,
      dial: dial,
      stats: stats,
      header: header,
    );

    if (nv.arrived) {
      return state(NavState.onRoute, 'You have arrived', 'at ${_short(end)}');
    }
    switch (nv.status) {
      case NavStatus.onRoute:
        final next = nv.nextDistM;
        if (nv.nextName == null || next == null) {
          final d = _dist(nv.remainingM);
          return state(
            NavState.onRoute,
            '${d.$1} ${d.$2}',
            'to the end of ${route.name}',
          );
        }
        final d = _dist(next);
        return state(NavState.onRoute, '${d.$1} ${d.$2}', 'to ${nv.nextName}');
      case NavStatus.offRoute:
        final String how;
        if (heading == null) {
          how = 'head ${_compassName(nv.bearingToGoDeg)} to the trail';
        } else if (dial.abs() > 135) {
          how = 'turn back · trail is behind you';
        } else {
          how = 'turn back · trail is to your ${dial < 0 ? 'left' : 'right'}';
        }
        return state(
          NavState.offRoute,
          '${nv.crossTrackM.round()} m off trail',
          how,
        );
      case NavStatus.wrongWay:
        return nv.reversed
            ? state(
                NavState.wrongWay,
                'Heading the wrong way',
                'turn around to continue',
              )
            : state(
                NavState.wrongWay,
                'Heading back to start',
                'turn around to continue',
              );
      case NavStatus.gpsLost:
        return state(
          NavState.gpsLost,
          'GPS signal weak',
          'keep to the trail · distances paused',
        );
    }
  }

  static String? _alert(List<IssueView> issues) {
    for (final i in issues) {
      if (i.severity == 'critical') return '${i.message} · ${i.fixHint}';
    }
    return null;
  }

  static String _position(double lat, double lon) =>
      '${lat.abs().toStringAsFixed(4)}° ${lat < 0 ? 'S' : 'N'}  '
      '${lon.abs().toStringAsFixed(4)}° ${lon < 0 ? 'W' : 'E'}';

  static String _thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}
