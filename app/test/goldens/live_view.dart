import 'package:core_model/core_model.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:trek_core/trek_core.dart';

/// A real-trek view as the core would produce it, for tests and goldens.
ActiveTrekView live({List<IssueView> issues = const [], int pinCount = 0}) =>
    ActiveTrekView.fromCore(
      CoreStateMessage(
        state: const TrekState(
          activity: Activity.moving,
          emergency: NoEmergency(),
          mapOpen: false,
        ),
        sos: const SosSummary.none(),
        issues: issues,
        stats: const TrekStats(
          distanceM: 2400,
          climbM: 320,
          elapsed: Duration(hours: 2, minutes: 10),
          altitudeM: 3214,
        ),
        battery: 78,
        fix: LocationFix(
          latitude: 27,
          longitude: 88,
          accuracyM: 6,
          gpsTime: DateTime.utc(2026, 10, 28),
          altitudeM: 3214,
        ),
        at: DateTime.utc(2026, 10, 28),
        pinCount: pinCount,
      ),
    );
