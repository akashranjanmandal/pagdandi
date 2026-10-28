// Long JSON literals are clearer on one line.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 10, 27, 14, 30, 15, 250);

void main() {
  final states = {
    'idle': TrekState.idle,
    'moving': const TrekState(
      activity: Activity.moving,
      emergency: NoEmergency(),
      mapOpen: false,
    ),
    'stationary with map': const TrekState(
      activity: Activity.stationary,
      emergency: NoEmergency(),
      mapOpen: true,
    ),
    'fall countdown': TrekState(
      activity: Activity.moving,
      emergency: FallCountdown(t0.add(const Duration(seconds: 60))),
      mapOpen: false,
    ),
    'lost': const TrekState(
      activity: Activity.stationary,
      emergency: LostMode(),
      mapOpen: false,
    ),
    'sos': const TrekState(
      activity: Activity.moving,
      emergency: SosActive(),
      mapOpen: false,
    ),
    'friend sos': const TrekState(
      activity: Activity.moving,
      emergency: FriendSos('rahul'),
      mapOpen: false,
    ),
  };

  for (final e in states.entries) {
    test('round-trips: ${e.key}', () {
      expect(decodeSnapshot(encodeSnapshot(e.value)), e.value);
    });
  }

  test('the fall deadline keeps millisecond precision', () {
    final s = TrekState(
      activity: Activity.moving,
      emergency: FallCountdown(t0),
      mapOpen: false,
    );
    final back = decodeSnapshot(encodeSnapshot(s))!;
    expect((back.emergency as FallCountdown).deadline, t0);
  });

  test('the snapshot is versioned JSON', () {
    final m =
        jsonDecode(encodeSnapshot(TrekState.idle)) as Map<String, Object?>;
    expect(m['v'], kSnapshotVersion);
    expect(m['activity'], 'idle');
  });

  group('bad input never throws and never invents state', () {
    test('not JSON', () => expect(decodeSnapshot('{{{'), isNull));
    test('not an object', () => expect(decodeSnapshot('[1,2]'), isNull));
    test('empty', () => expect(decodeSnapshot(''), isNull));

    test('a newer version is not understood', () {
      final m =
          jsonDecode(encodeSnapshot(TrekState.idle)) as Map<String, Object?>
            ..['v'] = kSnapshotVersion + 1;
      expect(decodeSnapshot(jsonEncode(m)), isNull);
    });

    test('an unknown activity', () {
      expect(
        decodeSnapshot(
          '{"v":1,"activity":"flying","mapOpen":false,"emergency":{"type":"none"}}',
        ),
        isNull,
      );
    });

    test('an unknown emergency type', () {
      expect(
        decodeSnapshot(
          '{"v":1,"activity":"idle","mapOpen":false,"emergency":{"type":"alien"}}',
        ),
        isNull,
      );
    });

    test('missing fields', () {
      expect(decodeSnapshot('{"v":1}'), isNull);
      expect(decodeSnapshot('{"v":1,"activity":"idle"}'), isNull);
      expect(
        decodeSnapshot(
          '{"v":1,"activity":"idle","mapOpen":false,"emergency":{"type":"fall"}}',
        ),
        isNull,
      );
      expect(
        decodeSnapshot(
          '{"v":1,"activity":"idle","mapOpen":false,"emergency":{"type":"friend"}}',
        ),
        isNull,
      );
      expect(
        decodeSnapshot(
          '{"v":1,"activity":"idle","mapOpen":false,"emergency":"none"}',
        ),
        isNull,
      );
    });

    test('wrong field types', () {
      expect(
        decodeSnapshot(
          '{"v":1,"activity":3,"mapOpen":false,"emergency":{"type":"none"}}',
        ),
        isNull,
      );
      expect(
        decodeSnapshot(
          '{"v":1,"activity":"idle","mapOpen":"no","emergency":{"type":"none"}}',
        ),
        isNull,
      );
      expect(
        decodeSnapshot(
          '{"v":1,"activity":"idle","mapOpen":false,"emergency":{"type":"fall","deadline":"not a date"}}',
        ),
        isNull,
      );
    });
  });
}
