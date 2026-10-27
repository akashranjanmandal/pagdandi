import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Design rule: the sos colour appears only in SOS, Friend SOS, danger pins
/// and danger zone states. Any file that uses `.sos` colour must be listed
/// here, and adding to the list is a deliberate design decision.
const _allowed = <String>{
  'lib/design/palette.dart', // the token definition itself
  'lib/design/sos_colour.dart', // the only accessor UI code may call
};

void main() {
  test('sos colour is only referenced from allow-listed files', () {
    final offenders = <String>[];
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final path = f.path.replaceAll(r'\', '/');
      if (_allowed.contains(path)) continue;
      final text = f.readAsStringSync();
      if (RegExp(r'\.sos\b|tintSos').hasMatch(text)) offenders.add(path);
    }
    expect(
      offenders,
      isEmpty,
      reason: 'sos colour used outside the allow-list',
    );
  });

  test('the allow-listed accessor exists', () {
    expect(File('lib/design/sos_colour.dart').existsSync(), isTrue);
  });
}
