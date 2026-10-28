import 'package:meta/meta.dart';

/// State of one line of a status checklist.
enum RowState {
  /// Finished and true.
  done,

  /// Happening now (pulses).
  live,

  /// Waiting or only partly done.
  wait,

  /// Off.
  off,
}

/// How far the SOS SMS has got. The wording never claims more than is true:
/// nothing delivered is "SOS active", never "delivered".
@immutable
class SosDelivery {
  /// Creates a delivery state: [delivered] of [total] contacts.
  const SosDelivery({
    required this.total,
    required this.delivered,
    this.beacon = false,
  }) : assert(total >= 0, 'contacts cannot be negative'),
       assert(delivered >= 0 && delivered <= total, 'delivered within total');

  /// Contacts the SMS was addressed to.
  final int total;

  /// Contacts whose phone confirmed delivery.
  final int delivered;

  /// Whether a real beacon is broadcasting. Nothing may claim it otherwise.
  final bool beacon;

  /// Big headline.
  String get headline {
    if (delivered == 0) return 'SOS active';
    if (delivered < total) return 'SOS delivered to $delivered of $total';
    return 'SOS delivered';
  }

  String get _beaconSuffix => beacon ? ' · beacon on' : '';

  /// Line under the headline (primary text colour).
  String get subline {
    if (total == 0) return 'No contacts to message · call for help';
    if (delivered == 0) {
      return 'SMS will send at first signal$_beaconSuffix';
    }
    if (delivered < total) {
      final left = total - delivered;
      final noun = left == 1 ? 'contact' : 'contacts';
      return '$left $noun still queued$_beaconSuffix';
    }
    return '$total of $total contacts received it$_beaconSuffix';
  }

  /// Status word for the SMS checklist row.
  String get smsLabel {
    if (total == 0) return 'no contacts';
    if (delivered == 0) return 'queued';
    return 'delivered to $delivered of $total';
  }

  /// Row state of the SMS line: done only when every contact has it.
  RowState get smsState =>
      total > 0 && delivered == total ? RowState.done : RowState.wait;
}
