import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_common/core_common.dart';
import 'package:core_crypto/src/crc32.dart';
import 'package:core_crypto/src/group_key.dart';
import 'package:meta/meta.dart';

/// Why a scanned code is not a usable invite.
enum InviteError {
  /// Not a Pagdandi join link.
  notAnInvite,

  /// A newer app version made it.
  unsupportedVersion,

  /// Missing or undecodable fields.
  malformed,

  /// The scan was damaged.
  badChecksum,
}

/// What a QR code carries to pair a phone with a group: group id and key.
@immutable
class GroupInvite {
  /// Creates an invite.
  GroupInvite({
    required Uint8List groupId,
    required this.key,
    required this.name,
  }) : groupId = Uint8List.fromList(groupId);

  /// Creates a brand-new group (pass `Random.secure()` in production).
  factory GroupInvite.create({required String name, required Random random}) =>
      GroupInvite(
        groupId: Uint8List.fromList([
          for (var i = 0; i < 16; i++) random.nextInt(256),
        ]),
        key: GroupKey.generate(random),
        name: name,
      );

  /// 16-byte group id.
  final Uint8List groupId;

  /// The shared secret.
  final GroupKey key;

  /// Human name of the group.
  final String name;

  static String _b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');

  static Uint8List _unb64(String s) =>
      Uint8List.fromList(base64Url.decode(base64Url.normalize(s)));

  static int _check(String v, String g, String k, String n) =>
      crc32(utf8.encode('$v|$g|$k|$n'));

  /// The text to show as a QR code.
  String toQrPayload() {
    final g = _b64(groupId);
    final k = _b64(key.bytes);
    return Uri(
      scheme: 'pagdandi',
      host: 'join',
      queryParameters: {
        'v': '1',
        'g': g,
        'k': k,
        'n': name,
        'c': _check('1', g, k, name).toRadixString(16),
      },
    ).toString();
  }

  /// Reads a scanned QR payload.
  static Result<GroupInvite, InviteError> parse(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri == null || uri.scheme != 'pagdandi' || uri.host != 'join') {
      return const Err(InviteError.notAnInvite);
    }
    final q = uri.queryParameters;
    if (q['v'] != '1') {
      return Err(
        q['v'] == null ? InviteError.malformed : InviteError.unsupportedVersion,
      );
    }
    final g = q['g'];
    final k = q['k'];
    final c = q['c'];
    if (g == null || k == null || c == null) {
      return const Err(InviteError.malformed);
    }
    final name = q['n'] ?? '';
    final Uint8List id;
    final Uint8List key;
    try {
      id = _unb64(g);
      key = _unb64(k);
    } on FormatException {
      return const Err(InviteError.malformed);
    }
    if (id.length != 16 || key.length != 32) {
      return const Err(InviteError.malformed);
    }
    if (_check('1', g, k, name).toRadixString(16) != c) {
      return const Err(InviteError.badChecksum);
    }
    return Ok(GroupInvite(groupId: id, key: GroupKey(key), name: name));
  }
}
