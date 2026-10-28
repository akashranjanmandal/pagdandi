import 'package:core_model/core_model.dart';
import 'package:test/test.dart';

OutboxEntry entry({
  SmsStatus status = SmsStatus.queued,
  int attempts = 0,
}) => OutboxEntry(
  id: 'sos-1-+911',
  to: '+911',
  body: 'help',
  kind: OutboxKind.sos,
  status: status,
  attempts: attempts,
  createdAt: DateTime.utc(2026, 10, 27, 9),
  nextAttemptAt: DateTime.utc(2026, 10, 27, 9),
);

void main() {
  test('copyWith changes only the given fields', () {
    final e = entry();
    final f = e.copyWith(status: SmsStatus.sending, attempts: 1);
    expect(f.status, SmsStatus.sending);
    expect(f.attempts, 1);
    expect(f.id, e.id);
    expect(f.body, e.body);
    expect(f.nextAttemptAt, e.nextAttemptAt);
  });

  test('entries with equal fields are equal', () {
    expect(entry(), entry());
    expect(entry().hashCode, entry().hashCode);
    expect(entry(), isNot(entry(attempts: 1)));
  });

  test('pending means not yet delivered', () {
    expect(entry().isPending, isTrue);
    expect(entry(status: SmsStatus.sending).isPending, isTrue);
    expect(entry(status: SmsStatus.sent).isPending, isTrue);
    expect(entry(status: SmsStatus.failed).isPending, isTrue);
    expect(entry(status: SmsStatus.delivered).isPending, isFalse);
    expect(entry(status: SmsStatus.cancelled).isPending, isFalse);
  });

  test('a lastAttemptAt can be set and cleared by copyWith', () {
    final t = DateTime.utc(2026, 10, 27, 9, 5);
    final e = entry().copyWith(lastAttemptAt: t);
    expect(e.lastAttemptAt, t);
    expect(e.copyWith().lastAttemptAt, t);
  });

  test('converts to the SMS message the gateway sends', () {
    final m = entry().toSms();
    expect(m, const SmsMessage(id: 'sos-1-+911', to: '+911', body: 'help'));
  });
}
