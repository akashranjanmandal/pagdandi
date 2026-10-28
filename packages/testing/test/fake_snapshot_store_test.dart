import 'package:test/test.dart';
import 'package:testing/testing.dart';

void main() {
  test('keeps the latest snapshot', () async {
    final s = FakeSnapshotStore();
    expect(await s.latest(), isNull);
    await s.save('{"a":1}', at: DateTime.utc(2026));
    await s.save('{"a":2}', at: DateTime.utc(2026));
    expect(await s.latest(), '{"a":2}');
    expect(s.saved, ['{"a":1}', '{"a":2}']);
  });

  test('can simulate a failing disk', () async {
    final s = FakeSnapshotStore()..failWrites = true;
    await expectLater(s.save('x', at: DateTime.utc(2026)), throwsStateError);
    expect(await s.latest(), isNull);
  });

  test('a restored store keeps the data (restart)', () async {
    final s = FakeSnapshotStore();
    await s.save('{"a":1}', at: DateTime.utc(2026));
    expect(await FakeSnapshotStore.restoreFrom(s).latest(), '{"a":1}');
  });
}
