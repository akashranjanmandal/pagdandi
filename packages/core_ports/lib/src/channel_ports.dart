/// The core's side of the UI/core channel (the core runs headless).
abstract interface class CoreChannel {
  /// Commands sent by the UI, as JSON.
  Stream<String> get commands;

  /// Publishes the core's latest state to the UI, as JSON.
  Future<void> publish(String json);
}

/// The UI's side of the UI/core channel (the UI is a thin client).
abstract interface class UiChannel {
  /// The core's states, as JSON. The latest state arrives on connect.
  Stream<String> get states;

  /// Sends a command to the core, as JSON. Queued until the core is up.
  Future<void> send(String json);
}
