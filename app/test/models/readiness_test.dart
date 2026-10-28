import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/readiness.dart';

Readiness make({
  int contacts = 2,
  bool location = true,
  bool sms = true,
  bool notifications = true,
  bool background = true,
  bool card = true,
  bool running = false,
}) => Readiness(
  contactCount: contacts,
  location: location,
  sms: sms,
  notifications: notifications,
  backgroundLocation: background,
  cardFilled: card,
  trekRunning: running,
);

void main() {
  test('everything in place: ready, no reason to block', () {
    final r = make();
    expect(r.canStart, isTrue);
    expect(r.blockedReason, isNull);
    expect(r.rows.every((x) => x.status == ReadyStatus.ok), isTrue);
  });

  test('critical items are contacts, location and SMS', () {
    for (final r in [
      make(contacts: 0),
      make(location: false),
      make(sms: false),
    ]) {
      expect(r.canStart, isFalse);
    }
  });

  test('warnings never block the start', () {
    final r = make(notifications: false, background: false, card: false);
    expect(r.canStart, isTrue);
    expect(r.rows.where((x) => x.status == ReadyStatus.warn), hasLength(3));
  });

  test('the blocked reason counts what must be fixed', () {
    expect(make(contacts: 0).blockedReason, 'Fix 1 thing first');
    expect(
      make(contacts: 0, sms: false, location: false).blockedReason,
      'Fix 3 things first',
    );
  });

  test('critical rows sort before warnings so the worst is on top', () {
    final r = make(background: false, sms: false);
    expect(r.rows.first.id, ReadyItem.sms);
  });

  test('every row says its state in words, not colour alone', () {
    for (final x in make(contacts: 0, card: false).rows) {
      expect(x.stateText, isNotEmpty);
      expect(x.label, isNotEmpty);
    }
  });

  test('a running trek shows Open trek and never blocks', () {
    final r = make(contacts: 0, running: true);
    expect(r.canStart, isFalse);
    expect(r.showOpenTrek, isTrue);
    expect(r.blockedReason, isNull);
  });

  test('contacts row shows the count when present', () {
    final row = make(contacts: 3).rows.firstWhere(
      (x) => x.id == ReadyItem.contacts,
    );
    expect(row.stateText, '3 added');
  });
}
