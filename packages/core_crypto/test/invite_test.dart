import 'dart:math';
import 'dart:typed_data';

import 'package:core_crypto/core_crypto.dart';
import 'package:test/test.dart';

void main() {
  final invite = GroupInvite.create(name: 'Sandakphu crew', random: Random(11));

  test('a new invite has a 16-byte group id and a 32-byte key', () {
    expect(invite.groupId, hasLength(16));
    expect(invite.key.bytes, hasLength(32));
    expect(invite.name, 'Sandakphu crew');
  });

  test('the same randomness gives the same invite (deterministic tests)', () {
    final again = GroupInvite.create(name: 'x', random: Random(11));
    expect(again.groupId, invite.groupId);
    expect(again.key, invite.key);
  });

  test('round-trips through the QR payload', () {
    final r = GroupInvite.parse(invite.toQrPayload());
    expect(r.isOk, isTrue);
    final got = r.valueOrNull!;
    expect(got.groupId, invite.groupId);
    expect(got.key, invite.key);
    expect(got.name, 'Sandakphu crew');
  });

  test('names with spaces, symbols and unicode survive', () {
    final i = GroupInvite.create(
      name: 'दार्जिलिंग & friends = 5?',
      random: Random(1),
    );
    expect(
      GroupInvite.parse(i.toQrPayload()).valueOrNull!.name,
      'दार्जिलिंग & friends = 5?',
    );
  });

  test('the payload is a pagdandi link and short enough for a clear QR', () {
    final p = invite.toQrPayload();
    expect(p, startsWith('pagdandi://join?'));
    expect(p.length, lessThan(160));
  });

  test('the payload does not contain the key in readable hex', () {
    final hex = invite.key.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    expect(invite.toQrPayload(), isNot(contains(hex)));
  });

  group('parse errors', () {
    String tweak(String Function(String) f) => f(invite.toQrPayload());

    test('not a pagdandi link', () {
      expect(
        GroupInvite.parse('https://example.com').errorOrNull,
        InviteError.notAnInvite,
      );
      expect(GroupInvite.parse('').errorOrNull, InviteError.notAnInvite);
      expect(
        GroupInvite.parse('pagdandi://other?x=1').errorOrNull,
        InviteError.notAnInvite,
      );
    });

    test('unsupported version', () {
      final p = tweak((s) => s.replaceFirst('v=1', 'v=2'));
      expect(GroupInvite.parse(p).errorOrNull, InviteError.unsupportedVersion);
    });

    test('a damaged scan is caught by the checksum', () {
      final p = tweak((s) => s.replaceFirst(RegExp('k=.'), 'k=A'));
      final r = GroupInvite.parse(p);
      expect(r.isOk, isFalse);
      expect([
        InviteError.badChecksum,
        InviteError.malformed,
      ], contains(r.errorOrNull));
    });

    test('a changed name fails the checksum', () {
      final p = tweak((s) => s.replaceFirst('Sandakphu', 'Sandakphx'));
      expect(GroupInvite.parse(p).errorOrNull, InviteError.badChecksum);
    });

    test('missing fields', () {
      expect(
        GroupInvite.parse('pagdandi://join?v=1').errorOrNull,
        InviteError.malformed,
      );
      expect(
        GroupInvite.parse('pagdandi://join?v=1&g=AAAA').errorOrNull,
        InviteError.malformed,
      );
    });

    test('wrong lengths after decoding', () {
      final short = Uri(
        scheme: 'pagdandi',
        host: 'join',
        queryParameters: {
          'v': '1',
          'g': 'AAAA',
          'k': 'AAAA',
          'n': 'x',
          'c': '0',
        },
      ).toString();
      expect(GroupInvite.parse(short).errorOrNull, InviteError.malformed);
    });

    test('garbage base64', () {
      final p = tweak((s) => s.replaceFirst(RegExp('g=[^&]*'), 'g=!!!!'));
      expect(GroupInvite.parse(p).errorOrNull, InviteError.malformed);
    });
  });

  test('the key from an invite works with the cipher on both phones', () async {
    final alice = GroupCipher(invite.key, random: Random(1));
    final bobKey = GroupInvite.parse(invite.toQrPayload()).valueOrNull!.key;
    final bob = GroupCipher(bobKey, random: Random(2));
    final sealed = await alice.encrypt(
      Uint8List.fromList([1, 2, 3]),
      aad: Uint8List(0),
    );
    expect((await bob.decrypt(sealed, aad: Uint8List(0))).valueOrNull, [
      1,
      2,
      3,
    ]);
  });
}
