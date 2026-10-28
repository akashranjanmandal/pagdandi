import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

class _Log implements Logger {
  final lines = <String>[];
  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => lines.add('${level.name}:$tag:$message');
}

/// Gateway that records what the store held at the moment of each send.
class _SpyGateway extends FakeSmsGateway {
  _SpyGateway(this.store);
  final FakeSmsOutboxStore store;
  final storedAtSend = <int>[];
  @override
  Future<void> send(SmsMessage message) async {
    storedAtSend.add((await store.all()).length);
    await super.send(message);
  }
}

class _Rig {
  _Rig({bool spy = false}) {
    gps.receive(clock.now());
    trusted = TrustedClock(system: clock, gps: gps);
    sms = spy ? _SpyGateway(store) : FakeSmsGateway();
    kernel = _make(store);
  }

  final clock = FakeClock(DateTime.utc(2026, 10, 27, 14));
  late final gps = FakeGpsTimeSource(clock);
  late final TrustedClock trusted;
  final signal = FakeSmsSignal();
  final store = FakeSmsOutboxStore();
  final log = _Log();
  late final FakeSmsGateway sms;
  late SosKernel kernel;

  SosKernel _make(FakeSmsOutboxStore s) => SosKernel(
    sms: sms,
    signal: signal,
    store: s,
    clock: trusted,
    logger: log,
  );

  SosKernel restart() {
    kernel.dispose();
    return kernel = _make(FakeSmsOutboxStore.restoreFrom(store));
  }

  SosReport report() => SosReport(
    name: 'Akash',
    fix: LocationFix(
      latitude: 27.041,
      longitude: 88.2663,
      accuracyM: 8,
      gpsTime: clock.now(),
    ),
    time: trusted.now(),
    batteryPercent: 41,
  );

  Future<String> raise({List<String> to = const ['+91A', '+91B', '+91C']}) =>
      kernel.raise(report: report(), contacts: to);

  void advance(Duration d) {
    clock.advance(d);
    gps.receive(clock.now());
  }
}

/// A signal monitor that starts in service.
class FakeSmsSignal extends FakeSignalMonitor {
  FakeSmsSignal() {
    set(SignalState.inService);
  }
}

void main() {
  late _Rig r;
  setUp(() => r = _Rig());

  group('raising an SOS', () {
    test(
      'writes every contact to the outbox BEFORE sending anything',
      () async {
        r = _Rig(spy: true);
        await r.kernel.start();
        await r.raise();
        expect((r.sms as _SpyGateway).storedAtSend, [3, 3, 3]);
      },
    );

    test('with signal it sends one SMS per contact', () async {
      await r.kernel.start();
      await r.raise();
      expect(r.sms.sent.map((m) => m.to), ['+91A', '+91B', '+91C']);
      expect(r.sms.sent.first.body, contains('SOS Akash'));
      expect((await r.store.all()).every((e) => e.attempts == 1), isTrue);
    });

    test('without signal nothing is sent and the SOS waits, queued', () async {
      r.signal.set(SignalState.noService);
      await r.kernel.start();
      await r.raise();
      expect(r.sms.sent, isEmpty);
      expect(r.kernel.current.queued, 3);
      expect(r.kernel.current.delivered, 0);
    });

    test('emergency-only service cannot send SMS, so it waits too', () async {
      r.signal.set(SignalState.emergencyOnly);
      await r.kernel.start();
      await r.raise();
      expect(r.sms.sent, isEmpty);
    });

    test('flushes at the first signal', () async {
      r.signal.set(SignalState.noService);
      await r.kernel.start();
      await r.raise();
      r.signal.set(SignalState.inService);
      await Future<void>.delayed(Duration.zero);
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(3));
    });

    test('a signal that is still not usable sends nothing', () async {
      r.signal.set(SignalState.noService);
      await r.kernel.start();
      await r.raise();
      r.signal.set(SignalState.emergencyOnly);
      await Future<void>.delayed(Duration.zero);
      expect(r.sms.sent, isEmpty);
    });

    test('raising twice does not send a second SOS', () async {
      await r.kernel.start();
      final a = await r.raise();
      final b = await r.raise();
      expect(b, a);
      expect(r.sms.sent, hasLength(3));
    });

    test('with no contacts the SOS is active but sends nothing', () async {
      await r.kernel.start();
      await r.raise(to: const []);
      expect(r.sms.sent, isEmpty);
      expect(r.kernel.current.total, 0);
      expect(r.kernel.current.active, isTrue);
    });

    test('rapid duplicate signal events never double-send', () async {
      r.signal.set(SignalState.noService);
      await r.kernel.start();
      await r.raise();
      r.signal
        ..set(SignalState.inService)
        ..set(SignalState.inService);
      await Future<void>.delayed(Duration.zero);
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(3));
    });
  });

  group('fail safe', () {
    test(
      'if the disk is full the SOS is still sent and nothing throws',
      () async {
        r.store.failWrites = true;
        await r.kernel.start();
        await r.raise();
        expect(r.sms.sent, hasLength(3));
        expect(r.log.lines.any((l) => l.startsWith('error:')), isTrue);
      },
    );

    test(
      'a radio that throws does not stop other contacts and is retried',
      () async {
        await r.kernel.start();
        r.signal.set(SignalState.inService);
        r.sms.sendError = StateError('no radio');
        await r.raise();
        expect(r.sms.sent, isEmpty);
        expect(r.kernel.current.failed, 3);
        r.sms.sendError = null;
        await r.kernel.tick();
        expect(r.sms.sent, isEmpty, reason: 'still inside the 30 s backoff');
        r.advance(const Duration(seconds: 31));
        await r.kernel.tick();
        expect(r.sms.sent, hasLength(3));
      },
    );

    test(
      'a store that cannot load at start does not stop the kernel',
      () async {
        final bad = _ThrowingLoadStore();
        final k = SosKernel(
          sms: r.sms,
          signal: r.signal,
          store: bad,
          clock: r.trusted,
          logger: r.log,
        );
        await k.start();
        await k.raise(report: r.report(), contacts: const ['+91A']);
        expect(r.sms.sent, hasLength(1));
        k.dispose();
      },
    );
  });

  group('delivery reports and retry', () {
    test('status reports move entries to sent and delivered', () async {
      await r.kernel.start();
      await r.raise();
      final id = (await r.store.all()).first.id;
      r.sms.report(id, SmsStatus.sent);
      await Future<void>.delayed(Duration.zero);
      expect(r.kernel.current.sent, 1);
      r.sms.report(id, SmsStatus.delivered);
      await Future<void>.delayed(Duration.zero);
      expect(r.kernel.current.delivered, 1);
      expect(r.kernel.current.sending, 2);
    });

    test('a late sent report cannot downgrade a delivered entry', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      final id = (await r.store.all()).single.id;
      r.sms
        ..report(id, SmsStatus.delivered)
        ..report(id, SmsStatus.sent);
      await Future<void>.delayed(Duration.zero);
      expect(r.kernel.current.delivered, 1);
      expect(r.kernel.current.sent, 0);
    });

    test('reports for unknown messages are ignored', () async {
      await r.kernel.start();
      r.sms.report('nope', SmsStatus.delivered);
      await Future<void>.delayed(Duration.zero);
      expect(r.kernel.current.total, 0);
    });

    test('a failed report schedules a retry with growing backoff', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      final id = (await r.store.all()).single.id;
      r.sms.report(id, SmsStatus.failed);
      await Future<void>.delayed(Duration.zero);
      expect(r.kernel.current.failed, 1);
      r.advance(const Duration(seconds: 29));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(1));
      r.advance(const Duration(seconds: 2));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(2));
      r.sms.report(id, SmsStatus.failed);
      await Future<void>.delayed(Duration.zero);
      r.advance(const Duration(seconds: 59));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(2), reason: 'second backoff is 60 s');
      r.advance(const Duration(seconds: 2));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(3));
    });

    test('a message stuck in sending with no report is retried', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      r.advance(const Duration(minutes: 1));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(1), reason: 'still inside the send timeout');
      r.advance(const Duration(minutes: 2));
      await r.kernel.tick();
      expect(r.kernel.current.failed, 1);
      r.advance(const Duration(minutes: 1));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(2));
    });

    test('sent but never confirmed is sent again after a while', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      final id = (await r.store.all()).single.id;
      r.sms.report(id, SmsStatus.sent);
      await Future<void>.delayed(Duration.zero);
      r.advance(const Duration(minutes: 4));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(1));
      r.advance(const Duration(minutes: 2));
      await r.kernel.tick();
      r.advance(const Duration(minutes: 1));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(2));
    });

    test('delivered entries are never sent again', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      final id = (await r.store.all()).single.id;
      r.sms.report(id, SmsStatus.delivered);
      await Future<void>.delayed(Duration.zero);
      r.advance(const Duration(hours: 1));
      await r.kernel.tick();
      expect(r.sms.sent, hasLength(1));
    });

    test(
      'a store that fails on a status update does not break the kernel',
      () async {
        await r.kernel.start();
        await r.raise(to: const ['+91A']);
        final id = (await r.store.all()).single.id;
        r.store.failWrites = true;
        r.sms.report(id, SmsStatus.delivered);
        await Future<void>.delayed(Duration.zero);
        expect(r.kernel.current.delivered, 1);
      },
    );

    test('the summary stream announces every change', () async {
      await r.kernel.start();
      final seen = <int>[];
      r.kernel.summary.listen((s) => seen.add(s.delivered));
      await r.raise(to: const ['+91A']);
      final id = (await r.store.all()).single.id;
      r.sms.report(id, SmsStatus.delivered);
      await Future<void>.delayed(Duration.zero);
      expect(seen.last, 1);
    });
  });

  group('restart and reboot', () {
    test(
      'after a restart pending entries are sent at the first signal',
      () async {
        r.signal.set(SignalState.noService);
        await r.kernel.start();
        await r.raise();
        final k = r.restart();
        r.signal.set(SignalState.inService);
        await k.start();
        expect(r.sms.sent, hasLength(3));
        expect(k.current.active, isTrue);
        expect(k.current.total, 3);
      },
    );

    test('delivered entries are not resent after a restart', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      final id = (await r.store.all()).single.id;
      r.sms.report(id, SmsStatus.delivered);
      await Future<void>.delayed(Duration.zero);
      final k = r.restart();
      await k.start();
      expect(r.sms.sent, hasLength(1));
      expect(k.current.delivered, 1);
      expect(k.current.active, isTrue);
    });

    test('an empty store starts inactive', () async {
      final k = r.restart();
      await k.start();
      expect(k.current.active, isFalse);
    });

    test('a cancelled SOS stays cancelled after a restart', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      await r.kernel.cancel(name: 'Akash');
      final k = r.restart();
      await k.start();
      expect(k.current.active, isFalse);
    });

    test('with several SOS in history only the latest counts', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      await r.kernel.cancel(name: 'Akash');
      r.advance(const Duration(minutes: 5));
      await r.raise(to: const ['+91B']);
      final k = r.restart();
      await k.start();
      expect(k.current.active, isTrue);
      expect(k.current.total, 1);
    });
  });

  group('cancel', () {
    test('contacts who were sent the SOS get a cancel message', () async {
      await r.kernel.start();
      await r.raise(to: const ['+91A', '+91B']);
      await r.kernel.cancel(name: 'Akash');
      final cancels = r.sms.sent.where((m) => m.body.contains('cancelled'));
      expect(cancels.map((m) => m.to), ['+91A', '+91B']);
      expect(r.kernel.current.active, isFalse);
    });

    test('an SOS that never left the phone is dropped silently', () async {
      r.signal.set(SignalState.noService);
      await r.kernel.start();
      await r.raise(to: const ['+91A']);
      await r.kernel.cancel(name: 'Akash');
      r.signal.set(SignalState.inService);
      await Future<void>.delayed(Duration.zero);
      await r.kernel.tick();
      expect(r.sms.sent, isEmpty);
      expect(r.kernel.current.cancelled, 1);
    });

    test(
      'a failed (never sent) SOS is dropped, not announced as cancelled',
      () async {
        await r.kernel.start();
        r.sms.sendError = StateError('x');
        await r.raise(to: const ['+91A']);
        r.sms.sendError = null;
        await r.kernel.cancel(name: 'Akash');
        expect(r.sms.sent, isEmpty);
        expect(r.kernel.current.cancelled, 1);
      },
    );

    test('cancel with no SOS active does nothing', () async {
      await r.kernel.start();
      await r.kernel.cancel(name: 'Akash');
      expect(r.sms.sent, isEmpty);
    });

    test('a new SOS can be raised after cancelling', () async {
      await r.kernel.start();
      final a = await r.raise(to: const ['+91A']);
      await r.kernel.cancel(name: 'Akash');
      r.advance(const Duration(minutes: 1));
      final b = await r.raise(to: const ['+91A']);
      expect(b, isNot(a));
      expect(r.kernel.current.active, isTrue);
    });
  });

  group('lifecycle', () {
    test(
      'a failing job reports its error but never blocks later jobs',
      () async {
        final bad = _BrokenSignal();
        final k = SosKernel(
          sms: r.sms,
          signal: bad,
          store: r.store,
          clock: r.trusted,
          logger: r.log,
        );
        await expectLater(k.start(), throwsStateError);
        bad.broken = false;
        await k.flush();
        await k.tick();
        k.dispose();
      },
    );

    test('after dispose signal changes send nothing', () async {
      r.signal.set(SignalState.noService);
      await r.kernel.start();
      await r.raise();
      r.kernel.dispose();
      r.signal.set(SignalState.inService);
      await Future<void>.delayed(Duration.zero);
      expect(r.sms.sent, isEmpty);
    });

    test('tick with nothing pending is a no-op', () async {
      await r.kernel.start();
      await r.kernel.tick();
      expect(r.sms.sent, isEmpty);
    });
  });
}

class _ThrowingLoadStore extends FakeSmsOutboxStore {
  @override
  Future<List<OutboxEntry>> all() async => throw StateError('db corrupt');
}

/// A signal monitor whose change stream can be made to throw.
class _BrokenSignal extends FakeSignalMonitor {
  bool broken = true;
  @override
  Stream<SignalState> get changes =>
      broken ? throw StateError('radio service gone') : super.changes;
}
