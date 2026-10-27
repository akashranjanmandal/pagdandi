import 'package:core_common/core_common.dart';
import 'package:test/test.dart';

void main() {
  test('Ok exposes its value', () {
    const Result<int, String> r = Ok(3);
    expect(r.isOk, isTrue);
    expect(r.valueOrNull, 3);
    expect(r.errorOrNull, isNull);
  });

  test('Err exposes its error', () {
    const Result<int, String> r = Err('bad');
    expect(r.isOk, isFalse);
    expect(r.valueOrNull, isNull);
    expect(r.errorOrNull, 'bad');
  });

  test('when picks the matching branch', () {
    const Result<int, String> ok = Ok(2);
    const Result<int, String> err = Err('x');
    expect(ok.when(ok: (v) => 'v$v', err: (e) => 'e$e'), 'v2');
    expect(err.when(ok: (v) => 'v$v', err: (e) => 'e$e'), 'ex');
  });

  test('map transforms Ok and leaves Err untouched', () {
    const Result<int, String> ok = Ok(2);
    const Result<int, String> err = Err('x');
    expect(ok.map((v) => v * 2).valueOrNull, 4);
    expect(err.map((v) => v * 2).errorOrNull, 'x');
  });

  test('equal results compare equal', () {
    expect(const Ok<int, String>(1), const Ok<int, String>(1));
    expect(const Err<int, String>('a'), const Err<int, String>('a'));
    const Result<int, String> ok = Ok(1);
    const Result<int, String> err = Err('1');
    expect(ok == err, isFalse);
  });
}
