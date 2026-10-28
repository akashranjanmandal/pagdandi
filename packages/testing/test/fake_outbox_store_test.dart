import 'package:core_model/core_model.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

OutboxEntry e(String id, DateTime at) => OutboxEntry(
  id: id,
  to: '+91',
  body: 'x',
  kind: OutboxKind.sos,
  status: SmsStatus.queued,
  attempts: 0,
  createdAt: at,
  nextAttemptAt: at,
);

void main() {
  test('stores entries and returns them oldest first', () async {
    final s = FakeSmsOutboxStore();
    await s.put(e('b', DateTime.utc(2026, 1, 1, 2)));
    await s.put(e('a', DateTime.utc(2026, 1, 1, 1)));
    expect((await s.all()).map((x) => x.id), ['a', 'b']);
  });

  test('put with the same id replaces the entry', () async {
    final s = FakeSmsOutboxStore();
    final t = DateTime.utc(2026);
    await s.put(e('a', t));
    await s.put(e('a', t).copyWith(attempts: 3));
    final all = await s.all();
    expect(all, hasLength(1));
    expect(all.single.attempts, 3);
  });

  test('can simulate a full disk: put throws and nothing is stored', () async {
    final s = FakeSmsOutboxStore()..failWrites = true;
    await expectLater(s.put(e('a', DateTime.utc(2026))), throwsStateError);
    expect(await s.all(), isEmpty);
  });

  test('a restored store keeps its data (survives a restart)', () async {
    final s = FakeSmsOutboxStore();
    await s.put(e('a', DateTime.utc(2026)));
    final restarted = FakeSmsOutboxStore.restoreFrom(s);
    expect((await restarted.all()).single.id, 'a');
  });
}
