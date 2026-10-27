import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:testing/testing.dart';

void main() {
  late FakeClock clock;
  late SimScheduler sim;

  FakeTransportNetwork net({
    double rangeM = 100,
    double loss = 0,
    double duplicate = 0,
    Duration latency = const Duration(milliseconds: 50),
    Duration jitter = Duration.zero,
    int seed = 1,
  }) => FakeTransportNetwork(
    sim,
    random: Random(seed),
    rangeM: rangeM,
    lossRate: loss,
    duplicateRate: duplicate,
    latency: latency,
    jitter: jitter,
  );

  setUp(() {
    clock = FakeClock(DateTime.utc(2026));
    sim = SimScheduler(clock);
  });

  List<String> collect(FakeTransport t) {
    final got = <String>[];
    t.messages.listen((m) => got.add(String.fromCharCodes(m.bytes)));
    return got;
  }

  Uint8List msg(String s) => Uint8List.fromList(s.codeUnits);

  test('delivers to peers in range after the latency', () async {
    final n = net();
    final a = n.node('a', x: 0, y: 0);
    final b = n.node('b', x: 50, y: 0);
    final got = collect(b);
    await a.start();
    await b.start();
    await a.broadcast(msg('hi'));
    sim.runFor(const Duration(milliseconds: 49));
    expect(got, isEmpty);
    sim.runFor(const Duration(milliseconds: 2));
    expect(got, ['hi']);
  });

  test('does not deliver out of range', () async {
    final n = net();
    final a = n.node('a', x: 0, y: 0);
    final c = n.node('c', x: 500, y: 0);
    final got = collect(c);
    await a.start();
    await c.start();
    await a.broadcast(msg('hi'));
    sim.runFor(const Duration(seconds: 1));
    expect(got, isEmpty);
  });

  test('a stopped node neither sends nor receives', () async {
    final n = net();
    final a = n.node('a', x: 0, y: 0);
    final b = n.node('b', x: 10, y: 0);
    final got = collect(b);
    await a.start();
    await a.broadcast(msg('hi'));
    sim.runFor(const Duration(seconds: 1));
    expect(got, isEmpty);
  });

  test(
    'moving into range emits a connect event, out of range a disconnect',
    () async {
      final n = net();
      final a = n.node('a', x: 0, y: 0);
      final b = n.node('b', x: 500, y: 0);
      final events = <String>[];
      a.peers.listen((e) => events.add('${e.peerId}:${e.connected}'));
      await a.start();
      await b.start();
      n.moveNode('b', x: 40, y: 0);
      n.moveNode('b', x: 400, y: 0);
      expect(events, ['b:true', 'b:false']);
    },
  );

  test('loss rate 1 drops everything, 0 drops nothing', () async {
    final lossy = net(loss: 1);
    final a = lossy.node('a', x: 0, y: 0);
    final b = lossy.node('b', x: 10, y: 0);
    final got = collect(b);
    await a.start();
    await b.start();
    await a.broadcast(msg('x'));
    sim.runFor(const Duration(seconds: 1));
    expect(got, isEmpty);
  });

  test('duplicate rate 1 delivers every message twice', () async {
    final n = net(duplicate: 1);
    final a = n.node('a', x: 0, y: 0);
    final b = n.node('b', x: 10, y: 0);
    final got = collect(b);
    await a.start();
    await b.start();
    await a.broadcast(msg('x'));
    sim.runFor(const Duration(seconds: 1));
    expect(got, ['x', 'x']);
  });

  test('jitter can reorder messages, deterministically for a seed', () async {
    Future<List<String>> run(int seed) async {
      final c = FakeClock(DateTime.utc(2026));
      final s = SimScheduler(c);
      final n = FakeTransportNetwork(
        s,
        random: Random(seed),
        latency: const Duration(milliseconds: 100),
        jitter: const Duration(milliseconds: 90),
      );
      final a = n.node('a', x: 0, y: 0);
      final b = n.node('b', x: 10, y: 0);
      final got = <String>[];
      b.messages.listen((m) => got.add(String.fromCharCodes(m.bytes)));
      await a.start();
      await b.start();
      for (var i = 0; i < 10; i++) {
        await a.broadcast(msg('$i'));
      }
      s.runFor(const Duration(seconds: 1));
      return got;
    }

    final first = await run(7);
    expect(first.toSet().length, 10);
    expect(first, isNot(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']));
    expect(await run(7), first);
  });
}
