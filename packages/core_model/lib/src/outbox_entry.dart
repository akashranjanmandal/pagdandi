import 'package:core_model/src/sms.dart';
import 'package:meta/meta.dart';

/// What an outbox message is for.
enum OutboxKind {
  /// The SOS itself.
  sos,

  /// "I am OK, SOS cancelled".
  cancel,
}

/// One SMS waiting in the outbox. The outbox is written before anything is
/// sent, so a crash, reboot or dead signal never loses an SOS.
@immutable
class OutboxEntry {
  /// Creates an entry.
  const OutboxEntry({
    required this.id,
    required this.to,
    required this.body,
    required this.kind,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.nextAttemptAt,
    this.lastAttemptAt,
  });

  /// Unique id (one per contact per SOS).
  final String id;

  /// Destination number.
  final String to;

  /// Text.
  final String body;

  /// Purpose.
  final OutboxKind kind;

  /// Where it is in its life.
  final SmsStatus status;

  /// How many times it has been handed to the radio.
  final int attempts;

  /// When it was created (trusted time).
  final DateTime createdAt;

  /// Earliest time to try (again).
  final DateTime nextAttemptAt;

  /// When it was last handed to the radio.
  final DateTime? lastAttemptAt;

  /// Not yet delivered or cancelled, so it still needs work. A failed entry
  /// is still pending: an SOS is retried until delivered.
  bool get isPending =>
      status != SmsStatus.delivered && status != SmsStatus.cancelled;

  /// The message the gateway sends.
  SmsMessage toSms() => SmsMessage(id: id, to: to, body: body);

  /// Copy with changes.
  OutboxEntry copyWith({
    SmsStatus? status,
    int? attempts,
    DateTime? nextAttemptAt,
    DateTime? lastAttemptAt,
  }) => OutboxEntry(
    id: id,
    to: to,
    body: body,
    kind: kind,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
  );

  @override
  bool operator ==(Object other) =>
      other is OutboxEntry &&
      other.id == id &&
      other.to == to &&
      other.body == body &&
      other.kind == kind &&
      other.status == status &&
      other.attempts == attempts &&
      other.createdAt == createdAt &&
      other.nextAttemptAt == nextAttemptAt &&
      other.lastAttemptAt == lastAttemptAt;

  @override
  int get hashCode => Object.hash(
    id,
    to,
    body,
    kind,
    status,
    attempts,
    createdAt,
    nextAttemptAt,
    lastAttemptAt,
  );
}
