import 'dart:convert';

import 'package:core_crypto/src/crc32.dart';
import 'package:test/test.dart';

void main() {
  test('matches the standard CRC-32 check value for "123456789"', () {
    expect(crc32(utf8.encode('123456789')), 0xCBF43926);
  });

  test('the CRC of nothing is zero', () {
    expect(crc32(const []), 0);
  });
}
