import 'package:core_db/core_db.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late PagdandiDatabase db;
  late PinRepository pins;

  setUp(() {
    db = PagdandiDatabase(NativeDatabase.memory());
    pins = PinRepository(db);
  });
  tearDown(() => db.close());

  Future<int> add(int n, {double? acc = 6}) => pins.add(
    at: DateTime.utc(2026, 12, 14, 9, n),
    lat: 30.1 + n / 1000,
    lon: 79.5,
    accuracyM: acc,
    label: 'Pin $n',
  );

  test('a pin keeps where and when it was dropped', () async {
    await add(1);
    final p = (await pins.all()).single;
    expect(p.label, 'Pin 1');
    expect(p.lat, closeTo(30.101, 1e-9));
    expect(p.lon, 79.5);
    expect(p.accuracyM, 6);
    expect(p.at, DateTime.utc(2026, 12, 14, 9, 1));
  });

  test('newest first, and counted', () async {
    await add(1);
    await add(2);
    await add(3);
    expect((await pins.all()).map((p) => p.label), ['Pin 3', 'Pin 2', 'Pin 1']);
    expect(await pins.count(), 3);
  });

  test('accuracy may be unknown', () async {
    await add(1, acc: null);
    expect((await pins.all()).single.accuracyM, isNull);
  });

  test('the table is bounded: the oldest pins make room', () async {
    final small = PinRepository(db, maxRows: 3);
    for (var i = 1; i <= 5; i++) {
      await small.add(
        at: DateTime.utc(2026, 12, 14, 9, i),
        lat: 30,
        lon: 79,
        accuracyM: 5,
        label: 'Pin $i',
      );
    }
    expect((await small.all()).map((p) => p.label), [
      'Pin 5',
      'Pin 4',
      'Pin 3',
    ]);
    expect(await small.count(), 3);
  });

  test('an empty table has none', () async {
    expect(await pins.all(), isEmpty);
    expect(await pins.count(), 0);
  });
}
