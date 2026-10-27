import 'dart:typed_data';

import 'package:core_model/core_model.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

void main() {
  test('a world runs several phones on one fake clock', () async {
    final world = SimWorld(start: DateTime.utc(2026, 10, 27, 9), seed: 3);
    final rahul = world.addPhone('rahul', x: 0, y: 0);
    final anita = world.addPhone('anita', x: 60, y: 0);
    await rahul.transport.start();
    await anita.transport.start();
    final heard = <String>[];
    anita.transport.messages.listen(
      (m) => heard.add(String.fromCharCodes(m.bytes)),
    );
    await rahul.transport.broadcast(Uint8List.fromList('hello'.codeUnits));
    world.run(const Duration(seconds: 1));
    expect(heard, ['hello']);
    expect(world.clock.elapsed(), const Duration(seconds: 1));
    expect(rahul.clock, same(anita.clock));
  });

  test('phones have independent sensors and outputs', () async {
    final world = SimWorld(start: DateTime.utc(2026), seed: 1);
    final a = world.addPhone('a', x: 0, y: 0);
    final b = world.addPhone('b', x: 0, y: 0);
    await a.haptic.play(HapticPattern.sos);
    expect(a.haptic.played, [HapticPattern.sos]);
    expect(b.haptic.played, isEmpty);
  });

  test('a duplicate phone id is rejected', () {
    final world = SimWorld(start: DateTime.utc(2026), seed: 1);
    world.addPhone('a', x: 0, y: 0);
    expect(() => world.addPhone('a', x: 1, y: 1), throwsArgumentError);
  });
}
