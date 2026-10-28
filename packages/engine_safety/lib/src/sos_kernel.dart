import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_safety/src/backoff.dart';
import 'package:engine_safety/src/sos_message.dart';
import 'package:meta/meta.dart';

/// How far the active SOS has got, counted per contact.
@immutable
class SosSummary {
  /// Creates a summary.
  const SosSummary({
    required this.active,
    required this.total,
    required this.queued,
    required this.sending,
    required this.sent,
    required this.delivered,
    required this.failed,
    required this.cancelled,
  });

  /// No SOS yet.
  const SosSummary.none()
    : active = false,
      total = 0,
      queued = 0,
      sending = 0,
      sent = 0,
      delivered = 0,
      failed = 0,
      cancelled = 0;

  /// Whether an SOS is running (raised and not cancelled).
  final bool active;

  /// Contacts the SOS was addressed to.
  final int total;

  /// Waiting to be sent.
  final int queued;

  /// Handed to the radio, no report yet.
  final int sending;

  /// Left the phone, delivery not confirmed.
  final int sent;

  /// Delivery confirmed.
  final int delivered;

  /// Failed, waiting to be retried.
  final int failed;

  /// Dropped because the SOS was cancelled before it left the phone.
  final int cancelled;
}

/// The SOS outbox: persisted BEFORE anything is sent, flushed whenever there
/// is signal, retried with backoff until delivered, recovered after a restart
/// or reboot. Depends on core packages only. Fail safe: a failing store or
/// radio never stops it and never makes it silent.
class SosKernel {
  /// Creates a kernel.
  SosKernel({
    required this._sms,
    required this._signal,
    required this._store,
    required this._clock,
    required Logger logger,
    this.backoff = const BackoffPolicy(),
    this.sendTimeout = const Duration(minutes: 2),
    this.sentResendAfter = const Duration(minutes: 5),
  }) : _log = logger;

  final SmsGateway _sms;
  final SignalMonitor _signal;
  final SmsOutboxStore _store;
  final TrustedClock _clock;
  final Logger _log;

  /// Retry delays.
  final BackoffPolicy backoff;

  /// How long a message may sit in "sending" without any report.
  final Duration sendTimeout;

  /// How long a message may sit in "sent" before it is sent again.
  final Duration sentResendAfter;

  static const _tag = 'sos';

  final _entries = <String, OutboxEntry>{};
  final _changes = StreamController<SosSummary>.broadcast(sync: true);
  StreamSubscription<SignalState>? _signalSub;
  StreamSubscription<SmsReport>? _reportSub;
  Future<void> _tail = Future<void>.value();
  String? _sosId;
  bool _active = false;

  /// Summary after every change.
  Stream<SosSummary> get summary => _changes.stream;

  /// Summary now.
  SosSummary get current {
    final id = _sosId;
    if (id == null) return const SosSummary.none();
    final mine = _entries.values
        .where((e) => e.kind == OutboxKind.sos && e.id.startsWith('$id|'))
        .toList();
    int n(SmsStatus s) => mine.where((e) => e.status == s).length;
    return SosSummary(
      active: _active,
      total: mine.length,
      queued: n(SmsStatus.queued),
      sending: n(SmsStatus.sending),
      sent: n(SmsStatus.sent),
      delivered: n(SmsStatus.delivered),
      failed: n(SmsStatus.failed),
      cancelled: n(SmsStatus.cancelled),
    );
  }

  /// Runs [job] after every earlier job, so state is never mutated
  /// concurrently.
  Future<T> _serial<T>(Future<T> Function() job) {
    final done = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        done.complete(await job());
      } on Object catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }

  /// Restores the outbox from storage, starts listening for signal and
  /// delivery reports, and sends whatever is pending (boot recovery).
  Future<void> start() => _serial(() async {
    try {
      for (final e in await _store.all()) {
        _entries[e.id] = e;
      }
    } on Object catch (e) {
      _log.error(_tag, 'could not load the outbox, starting empty', error: e);
    }
    _recoverActive();
    _signalSub = _signal.changes.listen((s) {
      if (s.canSendSms) unawaited(flush());
    });
    _reportSub = _sms.reports.listen((r) => unawaited(_onReport(r)));
    _emit();
    await _flush();
  });

  /// Raises an SOS to [contacts]. Idempotent while an SOS is active. The
  /// outbox is written before anything is sent.
  Future<String> raise({
    required SosReport report,
    required List<String> contacts,
  }) => _serial(() async {
    if (_active) return _sosId!;
    final now = _clock.now().time;
    final id = 'sos-${now.millisecondsSinceEpoch}';
    final body = formatSosMessage(report);
    for (final to in contacts) {
      final e = OutboxEntry(
        id: '$id|$to',
        to: to,
        body: body,
        kind: OutboxKind.sos,
        status: SmsStatus.queued,
        attempts: 0,
        createdAt: now,
        nextAttemptAt: now,
      );
      _entries[e.id] = e;
      await _persist(e);
    }
    _sosId = id;
    _active = true;
    _emit();
    await _flush();
    return id;
  });

  /// Cancels the active SOS. Contacts who may already have it get a cancel
  /// message; messages that never left the phone are dropped silently.
  Future<void> cancel({required String name}) => _serial(() async {
    if (!_active) return;
    final id = _sosId!;
    final time = _clock.now();
    final mine = _entries.values
        .where((e) => e.kind == OutboxKind.sos && e.id.startsWith('$id|'))
        .toList();
    for (final e in mine) {
      final left =
          e.status == SmsStatus.sending ||
          e.status == SmsStatus.sent ||
          e.status == SmsStatus.delivered;
      if (left) {
        final c = OutboxEntry(
          id: '${e.id}|cancel',
          to: e.to,
          body: formatCancelMessage(name: name, time: time),
          kind: OutboxKind.cancel,
          status: SmsStatus.queued,
          attempts: 0,
          createdAt: time.time,
          nextAttemptAt: time.time,
        );
        _entries[c.id] = c;
        await _persist(c);
      } else if (e.status != SmsStatus.cancelled) {
        final dropped = e.copyWith(status: SmsStatus.cancelled);
        _entries[e.id] = dropped;
        await _persist(dropped);
      }
    }
    _active = false;
    _emit();
    await _flush();
  });

  /// Sends everything that is due. Call when signal appears or on a timer.
  Future<void> flush() => _serial(_flush);

  /// Periodic housekeeping: retries stuck messages, then flushes.
  Future<void> tick() => _serial(() async {
    final now = _clock.now().time;
    for (final e in _entries.values.toList()) {
      final last = e.lastAttemptAt;
      if (last == null) continue;
      final age = now.difference(last);
      if ((e.status == SmsStatus.sending && age >= sendTimeout) ||
          (e.status == SmsStatus.sent && age >= sentResendAfter)) {
        await _markFailed(e, now);
      }
    }
    await _flush();
  });

  /// Stops listening. The stored outbox is untouched.
  void dispose() {
    unawaited(_signalSub?.cancel());
    unawaited(_reportSub?.cancel());
    unawaited(_changes.close());
  }

  /// The latest SOS that has not been cancelled is the active one.
  void _recoverActive() {
    final sos = _entries.values.where((e) => e.kind == OutboxKind.sos).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (sos.isEmpty) return;
    _sosId = sos.last.id.split('|').first;
    final cancelled = _entries.values.any(
      (e) =>
          e.id.startsWith('$_sosId|') &&
          (e.kind == OutboxKind.cancel || e.status == SmsStatus.cancelled),
    );
    _active = !cancelled;
  }

  Future<void> _flush() async {
    if (!_signal.current.canSendSms) return;
    final now = _clock.now().time;
    final due =
        _entries.values
            .where(
              (e) =>
                  (e.status == SmsStatus.queued ||
                      e.status == SmsStatus.failed) &&
                  !e.nextAttemptAt.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final e in due) {
      final sending = e.copyWith(
        status: SmsStatus.sending,
        attempts: e.attempts + 1,
        lastAttemptAt: now,
      );
      _entries[e.id] = sending;
      await _persist(sending);
      _emit();
      try {
        await _sms.send(sending.toSms());
      } on Object catch (err) {
        _log.warn(_tag, 'sending ${e.id} failed, will retry', error: err);
        await _markFailed(sending, now);
      }
    }
  }

  Future<void> _onReport(SmsReport r) => _serial(() async {
    final e = _entries[r.id];
    if (e == null || e.status == SmsStatus.delivered) return;
    if (r.status == SmsStatus.failed) {
      await _markFailed(e, _clock.now().time);
    } else {
      final updated = e.copyWith(status: r.status);
      _entries[e.id] = updated;
      await _persist(updated);
      _emit();
    }
  });

  Future<void> _markFailed(OutboxEntry e, DateTime now) async {
    final failed = e.copyWith(
      status: SmsStatus.failed,
      nextAttemptAt: now.add(backoff.delayFor(e.attempts)),
    );
    _entries[e.id] = failed;
    await _persist(failed);
    _emit();
  }

  /// Fail safe: if storage fails the SOS carries on from memory.
  Future<void> _persist(OutboxEntry e) async {
    try {
      await _store.put(e);
    } on Object catch (err) {
      _log.error(
        _tag,
        'outbox write failed, continuing from memory',
        error: err,
      );
    }
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(current);
  }
}
