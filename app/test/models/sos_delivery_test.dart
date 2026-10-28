import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';

void main() {
  test('nothing delivered: SOS active, SMS will send at first signal', () {
    const d = SosDelivery(total: 3, delivered: 0);
    expect(d.headline, 'SOS active');
    expect(d.subline, 'SMS will send at first signal');
    expect(d.smsLabel, 'queued');
    expect(d.smsState, RowState.wait);
  });

  test('partly delivered says exactly how many', () {
    const d = SosDelivery(total: 3, delivered: 2);
    expect(d.headline, 'SOS delivered to 2 of 3');
    expect(d.subline, '1 contact still queued');
    expect(d.smsLabel, 'delivered to 2 of 3');
    expect(d.smsState, RowState.wait);
  });

  test('plural and singular for the remaining contacts', () {
    expect(
      const SosDelivery(total: 3, delivered: 1).subline,
      '2 contacts still queued',
    );
  });

  test('all delivered', () {
    const d = SosDelivery(total: 3, delivered: 3);
    expect(d.headline, 'SOS delivered');
    expect(d.subline, '3 of 3 contacts received it');
    expect(d.smsLabel, 'delivered to 3 of 3');
    expect(d.smsState, RowState.done);
  });

  test('never claims delivery before any contact received it', () {
    const d = SosDelivery(total: 3, delivered: 0);
    expect(d.headline.contains('delivered'), isFalse);
    expect(d.subline.contains('received'), isFalse);
  });

  test('invalid counts are rejected', () {
    expect(
      () => SosDelivery(total: -1, delivered: 0),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => SosDelivery(total: 3, delivered: 4),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => SosDelivery(total: 3, delivered: -1),
      throwsA(isA<AssertionError>()),
    );
  });

  test('the beacon is only claimed when a real beacon is running', () {
    const on = SosDelivery(total: 3, delivered: 0, beacon: true);
    expect(on.subline, 'SMS will send at first signal · beacon on');
    const off = SosDelivery(total: 3, delivered: 0);
    expect(off.subline, isNot(contains('beacon')));
  });

  test(
    'no contacts: says so plainly, never counts a contact that is not there',
    () {
      const d = SosDelivery(total: 0, delivered: 0);
      expect(d.headline, 'SOS active');
      expect(d.subline, 'No contacts to message · call for help');
      expect(d.smsLabel, 'no contacts');
      expect(
        d.smsState,
        RowState.wait,
        reason: 'never "done" with nobody told',
      );
    },
  );
}
