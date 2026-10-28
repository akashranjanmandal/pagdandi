import 'dart:math';
import 'dart:typed_data';

import 'package:core_common/core_common.dart';
import 'package:core_crypto/core_crypto.dart';
import 'package:test/test.dart';

Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);

void main() {
  final key = GroupKey.generate(Random(1));
  final other = GroupKey.generate(Random(2));
  final aad = bytes('group-1|rahul|position');

  group('GroupKey', () {
    test('is 32 random bytes, different for different randomness', () {
      expect(key.bytes, hasLength(32));
      expect(key.bytes, isNot(other.bytes));
      expect(GroupKey.generate(Random(1)).bytes, key.bytes);
    });

    test('rejects the wrong length', () {
      expect(() => GroupKey(Uint8List(16)), throwsArgumentError);
    });

    test('never reveals itself when printed', () {
      expect('$key', isNot(contains('${key.bytes.first}')));
      expect('$key', contains('***'));
    });

    test('equal keys compare equal', () {
      expect(GroupKey(Uint8List.fromList(key.bytes)), key);
      expect(GroupKey(Uint8List.fromList(key.bytes)).hashCode, key.hashCode);
      expect(key, isNot(other));
    });
  });

  group('GroupCipher', () {
    test('decrypts what it encrypted', () async {
      final c = GroupCipher(key, random: Random(5));
      final sealed = await c.encrypt(bytes('27.041,88.2663'), aad: aad);
      final r = await c.decrypt(sealed, aad: aad);
      expect(r.valueOrNull, bytes('27.041,88.2663'));
    });

    test(
      'the sealed message is nonce + ciphertext + tag (12 + n + 16)',
      () async {
        final c = GroupCipher(key, random: Random(5));
        final sealed = await c.encrypt(bytes('hello'), aad: aad);
        expect(sealed.length, 12 + 5 + 16);
      },
    );

    test('empty messages work', () async {
      final c = GroupCipher(key, random: Random(5));
      final r = await c.decrypt(
        await c.encrypt(Uint8List(0), aad: aad),
        aad: aad,
      );
      expect(r.valueOrNull, isEmpty);
    });

    test(
      'every encryption uses a fresh nonce, so ciphertexts differ',
      () async {
        final c = GroupCipher(key, random: Random(5));
        final a = await c.encrypt(bytes('same'), aad: aad);
        final b = await c.encrypt(bytes('same'), aad: aad);
        expect(a, isNot(b));
        expect(a.sublist(0, 12), isNot(b.sublist(0, 12)));
      },
    );

    test('the wrong key fails, with an error not an exception', () async {
      final sealed = await GroupCipher(
        key,
        random: Random(5),
      ).encrypt(bytes('x'), aad: aad);
      final r = await GroupCipher(
        other,
        random: Random(5),
      ).decrypt(sealed, aad: aad);
      expect(r, isA<Err<Uint8List, CipherError>>());
      expect(r.errorOrNull, CipherError.authenticationFailed);
    });

    test('a flipped bit anywhere is detected', () async {
      final c = GroupCipher(key, random: Random(5));
      final sealed = await c.encrypt(bytes('position data'), aad: aad);
      for (var i = 0; i < sealed.length; i++) {
        final bad = Uint8List.fromList(sealed)..[i] ^= 1;
        final r = await c.decrypt(bad, aad: aad);
        expect(r.isOk, isFalse, reason: 'byte $i');
      }
    });

    test(
      'different associated data is rejected (replay into another context)',
      () async {
        final c = GroupCipher(key, random: Random(5));
        final sealed = await c.encrypt(bytes('x'), aad: aad);
        final r = await c.decrypt(sealed, aad: bytes('group-2|rahul|position'));
        expect(r.errorOrNull, CipherError.authenticationFailed);
      },
    );

    test('truncated input is rejected as malformed', () async {
      final c = GroupCipher(key, random: Random(5));
      final r = await c.decrypt(Uint8List(27), aad: aad);
      expect(r.errorOrNull, CipherError.malformed);
    });

    test('matches the AES-GCM known-answer for a fixed nonce', () async {
      // NIST GCM test case 13 (AES-256): zero key, zero nonce, empty
      // plaintext and AAD => tag 530f8afbc74536b9a963b4f1c4cb738b
      final zero = GroupKey(Uint8List(32));
      final tag = await GroupCipher.sealWithNonce(
        zero,
        nonce: Uint8List(12),
        plaintext: Uint8List(0),
        aad: Uint8List(0),
      );
      expect(
        tag.sublist(12).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '530f8afbc74536b9a963b4f1c4cb738b',
      );
    });
  });
}
