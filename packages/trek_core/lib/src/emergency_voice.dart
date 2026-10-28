import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_trekstate/engine_trekstate.dart';

/// Speaks the emergency lines from docs/design/voice-scripts.md. It says only
/// what is true: "delivered" is spoken only once a contact's phone confirmed.
class EmergencyVoice {
  /// Creates the announcer.
  EmergencyVoice({
    required Stream<TrekState> states,
    required Stream<SosSummary> sos,
    required this._voice,
    required Logger logger,
  }) : _log = logger {
    _subs
      ..add(states.listen(_onState))
      ..add(sos.listen(_onSos));
  }

  final VoiceOutput _voice;
  final Logger _log;
  final _subs = <StreamSubscription<Object?>>[];
  Emergency _last = const NoEmergency();
  var _deliveredSaid = false;

  void _onState(TrekState s) {
    final e = s.emergency;
    final changed = e.runtimeType != _last.runtimeType;
    _last = e;
    if (!changed) return;
    switch (e) {
      case FallCountdown():
        unawaited(
          _say(
            'Did you fall? Sending S.O.S. in 60 seconds. '
            'Tap I’m OK to cancel.',
            urgent: true,
          ),
        );
      case SosActive():
        _deliveredSaid = false;
        unawaited(
          _say('S.O.S. active. Your position will be sent at first signal.'),
        );
      case NoEmergency() || LostMode() || FriendSos():
        break;
    }
  }

  void _onSos(SosSummary s) {
    if (_last is! SosActive || _deliveredSaid || s.delivered < 1) return;
    _deliveredSaid = true;
    final noun = s.total == 1 ? 'contact' : 'contacts';
    unawaited(
      _say('S.O.S. delivered to ${s.delivered} of ${s.total} $noun.'),
    );
  }

  Future<void> _say(String text, {bool urgent = false}) async {
    try {
      await _voice.speak(text, urgent: urgent);
    } on Object catch (e) {
      _log.warn('voice', 'could not speak', error: e);
    }
  }

  /// Stops listening.
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }
}
