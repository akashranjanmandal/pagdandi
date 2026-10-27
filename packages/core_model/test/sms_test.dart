import 'package:core_model/core_model.dart';
import 'package:test/test.dart';

void main() {
  test('only delivered and failed are final', () {
    expect(SmsStatus.delivered.isFinal, isTrue);
    expect(SmsStatus.failed.isFinal, isTrue);
    expect(SmsStatus.queued.isFinal, isFalse);
    expect(SmsStatus.sending.isFinal, isFalse);
    expect(SmsStatus.sent.isFinal, isFalse);
  });

  test('messages and reports compare by value', () {
    expect(
      const SmsMessage(id: 'a', to: '+911', body: 'x'),
      const SmsMessage(id: 'a', to: '+911', body: 'x'),
    );
    expect(
      const SmsReport(id: 'a', status: SmsStatus.sent),
      const SmsReport(id: 'a', status: SmsStatus.sent),
    );
  });
}
