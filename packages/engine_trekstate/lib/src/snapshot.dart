import 'dart:convert';

import 'package:engine_trekstate/src/state.dart';

/// Version of the snapshot format. Bump it (and add a migration) when the
/// shape changes.
const int kSnapshotVersion = 1;

/// Encodes [s] as versioned JSON for the `state_snapshots` table.
String encodeSnapshot(TrekState s) => jsonEncode({
  'v': kSnapshotVersion,
  'activity': s.activity.name,
  'mapOpen': s.mapOpen,
  'emergency': switch (s.emergency) {
    NoEmergency() => {'type': 'none'},
    FallCountdown(:final deadline) => {
      'type': 'fall',
      'deadline': deadline.toUtc().toIso8601String(),
    },
    LostMode() => {'type': 'lost'},
    SosActive() => {'type': 'sos'},
    FriendSos(:final friendId) => {'type': 'friend', 'friendId': friendId},
  },
});

/// Decodes a snapshot, or null if it is corrupt, from a newer version, or
/// otherwise not understood. It never throws and never guesses.
TrekState? decodeSnapshot(String json) {
  final Object? raw;
  try {
    raw = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (raw is! Map<String, Object?> || raw['v'] != kSnapshotVersion) return null;
  final activity = Activity.values.asNameMap()[raw['activity']];
  final mapOpen = raw['mapOpen'];
  final emergency = _emergency(raw['emergency']);
  if (activity == null || mapOpen is! bool || emergency == null) return null;
  return TrekState(activity: activity, emergency: emergency, mapOpen: mapOpen);
}

Emergency? _emergency(Object? raw) {
  if (raw is! Map<String, Object?>) return null;
  switch (raw['type']) {
    case 'none':
      return const NoEmergency();
    case 'lost':
      return const LostMode();
    case 'sos':
      return const SosActive();
    case 'fall':
      final d = raw['deadline'];
      final t = d is String ? DateTime.tryParse(d) : null;
      return t == null ? null : FallCountdown(t.toUtc());
    case 'friend':
      final id = raw['friendId'];
      return id is String ? FriendSos(id) : null;
    default:
      return null;
  }
}
