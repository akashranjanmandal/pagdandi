/// Voice alerts and chimes (ducks music).
abstract interface class AudioOutput {
  /// Plays the two-note chime, then speaks [text].
  Future<void> speak(String text);

  /// Plays a short cue by name (e.g. roger beep, channel-busy beep).
  Future<void> cue(AudioCue cue);

  /// Stops speech and cues.
  Future<void> stop();

  /// Emits true when headphones are connected, false when removed.
  Stream<bool> get headphones;
}

/// Short non-speech sounds.
enum AudioCue {
  /// Two-note chime before a voice alert.
  chime,

  /// PTT start or end.
  roger,

  /// PTT channel busy.
  channelBusy,
}

/// Push-to-talk audio. The audio path is fully native; Dart only starts and
/// stops it and learns who is talking.
abstract interface class PttAudio {
  /// Starts capturing from the phone microphone and sending.
  Future<void> startTalking();

  /// Stops capturing.
  Future<void> stopTalking();

  /// Peer ids as they start (true) and stop (false) speaking to us.
  Stream<({String peerId, bool speaking})> get incoming;
}
