import 'dart:math';
import 'dart:typed_data';

import 'package:core_common/core_common.dart';
import 'package:core_crypto/src/group_key.dart';
import 'package:cryptography/cryptography.dart';

/// Why decryption failed.
enum CipherError {
  /// Too short to be a sealed message.
  malformed,

  /// Wrong key, wrong context, or the message was altered.
  authenticationFailed,
}

/// AES-256-GCM for group messages. A sealed message is
/// `nonce (12) | ciphertext | tag (16)`. The nonce is random per message.
class GroupCipher {
  /// Creates a cipher for [key]. [random] supplies nonces (inject a seeded
  /// one in tests; the default is secure).
  GroupCipher(this.key, {Random? random}) : _random = random ?? Random.secure();

  /// The group key.
  final GroupKey key;
  final Random _random;

  static final _aes = AesGcm.with256bits();

  /// Encrypts [plaintext], binding it to [aad] (group id, sender, type).
  Future<Uint8List> encrypt(Uint8List plaintext, {required Uint8List aad}) {
    final nonce = Uint8List.fromList([
      for (var i = 0; i < 12; i++) _random.nextInt(256),
    ]);
    return sealWithNonce(key, nonce: nonce, plaintext: plaintext, aad: aad);
  }

  /// Encrypts with an explicit [nonce]. Exposed for known-answer tests only:
  /// reusing a nonce under one key breaks AES-GCM.
  static Future<Uint8List> sealWithNonce(
    GroupKey key, {
    required Uint8List nonce,
    required Uint8List plaintext,
    required Uint8List aad,
  }) async {
    final box = await _aes.encrypt(
      plaintext,
      secretKey: SecretKey(key.bytes),
      nonce: nonce,
      aad: aad,
    );
    return Uint8List.fromList([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Decrypts a sealed message. Failures are returned, never thrown.
  Future<Result<Uint8List, CipherError>> decrypt(
    Uint8List sealed, {
    required Uint8List aad,
  }) async {
    if (sealed.length < 12 + 16) return const Err(CipherError.malformed);
    final box = SecretBox(
      sealed.sublist(12, sealed.length - 16),
      nonce: sealed.sublist(0, 12),
      mac: Mac(sealed.sublist(sealed.length - 16)),
    );
    try {
      final clear = await _aes.decrypt(
        box,
        secretKey: SecretKey(key.bytes),
        aad: aad,
      );
      return Ok(Uint8List.fromList(clear));
    } on SecretBoxAuthenticationError {
      return const Err(CipherError.authenticationFailed);
    }
  }
}
