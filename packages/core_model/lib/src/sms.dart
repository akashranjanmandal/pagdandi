import 'package:meta/meta.dart';

/// Lifecycle of an outgoing SMS.
enum SmsStatus {
  /// Stored in the outbox, not yet handed to the radio.
  queued(isFinal: false),

  /// Being sent.
  sending(isFinal: false),

  /// Left the phone.
  sent(isFinal: false),

  /// Delivery report received.
  delivered(isFinal: true),

  /// Sending failed.
  failed(isFinal: true),

  /// Dropped because the SOS was cancelled before it was sent.
  cancelled(isFinal: true);

  const SmsStatus({required this.isFinal});

  /// True when no further updates are expected.
  final bool isFinal;
}

/// An SMS to send.
@immutable
class SmsMessage {
  /// Creates a message.
  const SmsMessage({required this.id, required this.to, required this.body});

  /// Outbox id.
  final String id;

  /// Destination number.
  final String to;

  /// Text.
  final String body;

  @override
  bool operator ==(Object other) =>
      other is SmsMessage &&
      other.id == id &&
      other.to == to &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, to, body);
}

/// A status update for one SMS.
@immutable
class SmsReport {
  /// Creates a report.
  const SmsReport({required this.id, required this.status});

  /// Outbox id of the message.
  final String id;

  /// New status.
  final SmsStatus status;

  @override
  bool operator ==(Object other) =>
      other is SmsReport && other.id == id && other.status == status;

  @override
  int get hashCode => Object.hash(id, status);
}
