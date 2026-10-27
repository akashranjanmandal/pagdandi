import 'package:meta/meta.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/widgets/group_row.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';
import 'package:pagdandi_app/widgets/stat_triplet.dart';

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
    this.ptt = PttState.idle,
    this.uncertaintyRadius = 14,
  });

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

  /// Push-to-talk state.
  final PttState ptt;

  /// Radius of the GPS-lost uncertainty circle.
  final double uncertaintyRadius;
}
