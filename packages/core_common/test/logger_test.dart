import 'package:core_common/core_common.dart';
import 'package:test/test.dart';

class _Recorder implements Logger {
  final lines = <String>[];
  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => lines.add('${level.name}|$tag|$message|${error ?? ''}');
}

void main() {
  test('level helpers forward the right level', () {
    final r = _Recorder();
    r
      ..debug('t', 'a')
      ..info('t', 'b')
      ..warn('t', 'c')
      ..error('t', 'd', error: 'boom');
    expect(r.lines, ['debug|t|a|', 'info|t|b|', 'warn|t|c|', 'error|t|d|boom']);
  });

  test('NoopLogger swallows everything', () {
    const NoopLogger().info('t', 'x');
  });

  test('RedactingLogger masks registered secrets in message and error', () {
    final inner = _Recorder();
    RedactingLogger(
      inner,
      secrets: ['s3cr3t-key'],
    ).error('crypto', 'key=s3cr3t-key', error: 'failed with s3cr3t-key');
    expect(inner.lines.single, isNot(contains('s3cr3t-key')));
    expect(inner.lines.single, contains('key=***'));
  });

  test('RedactingLogger ignores empty secrets', () {
    final inner = _Recorder();
    RedactingLogger(inner, secrets: ['']).info('t', 'hello');
    expect(inner.lines.single, 'info|t|hello|');
  });

  test('secrets can be added after construction', () {
    final inner = _Recorder();
    final l = RedactingLogger(inner)..addSecret('abc123');
    l.info('t', 'x abc123 y');
    expect(inner.lines.single, 'info|t|x *** y|');
  });
}
