/// Severity of a log line.
enum LogLevel {
  /// Detailed diagnostics.
  debug,

  /// Normal events.
  info,

  /// Something unexpected but handled.
  warn,

  /// A failure.
  error,
}

/// Logging interface. Implementations write to the rotating local log.
// A port is a deliberate one-method interface: fakes and adapters implement it.
// ignore: one_member_abstracts
abstract interface class Logger {
  /// Records one line.
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Convenience level methods for any [Logger].
extension LoggerLevels on Logger {
  /// Logs at [LogLevel.debug].
  void debug(String tag, String message) => log(LogLevel.debug, tag, message);

  /// Logs at [LogLevel.info].
  void info(String tag, String message) => log(LogLevel.info, tag, message);

  /// Logs at [LogLevel.warn].
  void warn(String tag, String message, {Object? error}) =>
      log(LogLevel.warn, tag, message, error: error);

  /// Logs at [LogLevel.error].
  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
}

/// Logger that discards everything.
class NoopLogger implements Logger {
  /// Creates a no-op logger.
  const NoopLogger();

  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

/// Wraps a [Logger] and masks registered secrets (keys are never logged).
class RedactingLogger implements Logger {
  /// Creates a redacting logger around [inner].
  RedactingLogger(this.inner, {Iterable<String> secrets = const []}) {
    secrets.forEach(addSecret);
  }

  /// The wrapped logger.
  final Logger inner;
  final _secrets = <String>{};

  /// Registers [secret]; empty strings are ignored.
  void addSecret(String secret) {
    if (secret.isNotEmpty) _secrets.add(secret);
  }

  String _mask(String text) =>
      _secrets.fold(text, (t, s) => t.replaceAll(s, '***'));

  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    inner.log(
      level,
      tag,
      _mask(message),
      error: error == null ? null : _mask('$error'),
      stackTrace: stackTrace,
    );
  }
}
