import 'package:core_common/core_common.dart';
import 'package:test/test.dart';

void main() {
  test('SystemClock returns UTC wall time close to now', () {
    final c = SystemClock();
    final now = c.now();
    expect(now.isUtc, isTrue);
    expect(now.difference(DateTime.now().toUtc()).abs().inSeconds, lessThan(2));
  });

  test('SystemClock monotonic time never goes backwards', () {
    final c = SystemClock();
    final a = c.elapsed();
    final b = c.elapsed();
    expect(b >= a, isTrue);
  });

  test('Timestamp compares by value and prints both fields', () {
    final t = DateTime.utc(2026);
    expect(
      Timestamp(time: t, gpsTrusted: true),
      Timestamp(time: t, gpsTrusted: true),
    );
    expect(
      Timestamp(time: t, gpsTrusted: true).hashCode,
      Timestamp(time: t, gpsTrusted: true).hashCode,
    );
    expect(
      Timestamp(time: t, gpsTrusted: true),
      isNot(Timestamp(time: t, gpsTrusted: false)),
    );
    expect(
      Timestamp(time: t, gpsTrusted: false).toString(),
      contains('gpsTrusted: false'),
    );
  });

  test('Ok and Err have consistent hash codes', () {
    expect(
      const Ok<int, String>(1).hashCode,
      const Ok<int, String>(1).hashCode,
    );
    expect(
      const Err<int, String>('a').hashCode,
      const Err<int, String>('a').hashCode,
    );
  });
}
