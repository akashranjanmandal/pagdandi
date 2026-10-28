import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// The 256-bit secret shared by every phone in a group. It never appears in
/// logs or in `toString`.
@immutable
class GroupKey {
  /// Wraps 32 bytes.
  GroupKey(Uint8List bytes) : bytes = Uint8List.fromList(bytes) {
    if (bytes.length != 32) {
      throw ArgumentError.value(bytes.length, 'bytes.length', 'must be 32');
    }
  }

  /// Generates a key from [random] (pass `Random.secure()` in production).
  factory GroupKey.generate(Random random) => GroupKey(
    Uint8List.fromList([for (var i = 0; i < 32; i++) random.nextInt(256)]),
  );

  /// The raw key bytes.
  final Uint8List bytes;

  @override
  bool operator ==(Object other) {
    if (other is! GroupKey) return false;
    var diff = 0;
    for (var i = 0; i < 32; i++) {
      diff |= bytes[i] ^ other.bytes[i];
    }
    return diff == 0;
  }

  @override
  int get hashCode => Object.hashAll(bytes);

  @override
  String toString() => 'GroupKey(***)';
}
