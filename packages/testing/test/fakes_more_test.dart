import 'dart:typed_data';

import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

void main() {
  test('FakeTorchOutput keeps steady light and strobe separate', () async {
    final t = FakeTorchOutput();
    await t.setOn(on: true);
    expect(t.isOn, isTrue);
    expect(t.strobing, isFalse);
  });

  test(
    'FakeAudioOutput records speech with its chime, cues and headphones',
    () async {
      final a = FakeAudioOutput();
      final phones = <bool>[];
      a.headphones.listen(phones.add);
      await a.speak('Fork in 80 metres');
      await a.cue(AudioCue.roger);
      await a.stop();
      a.setHeadphones(connected: true);
      expect(a.spoken, ['Fork in 80 metres']);
      expect(a.cues, [AudioCue.chime, AudioCue.roger]);
      expect(phones, [true]);
    },
  );

  test('FakePttAudio tracks talking and reports peers speaking', () async {
    final p = FakePttAudio();
    final seen = <({String peerId, bool speaking})>[];
    p.incoming.listen(seen.add);
    await p.startTalking();
    expect(p.talking, isTrue);
    await p.stopTalking();
    expect(p.talking, isFalse);
    p.peer('anita', speaking: true);
    expect(seen.single.peerId, 'anita');
    expect(seen.single.speaking, isTrue);
  });

  test('FakeBeaconTransport broadcasts, scans and hears beacons', () async {
    final b = FakeBeaconTransport();
    final heard = <BeaconSighting>[];
    b.sightings.listen(heard.add);
    await b.startBeacon(Uint8List.fromList([1]));
    expect(b.broadcasting, [1]);
    await b.stopBeacon();
    expect(b.broadcasting, isNull);
    await b.startScan();
    expect(b.scanning, isTrue);
    b.hear(Uint8List.fromList([2]), rssi: -60);
    await b.stopScan();
    expect(b.scanning, isFalse);
    expect(heard.single.rssi, -60);
    expect(b.capabilities.codedPhy, isTrue);
  });

  test(
    'FakeMotionSensor, FakeAccelerometer and FakeBarometer relay events',
    () {
      final m = FakeMotionSensor();
      var motions = 0;
      m.significantMotion.listen((_) => motions++);
      m.trigger();
      expect(motions, 1);

      final acc = FakeAccelerometer();
      final samples = <AccelSample>[];
      acc.samples(const Duration(milliseconds: 20)).listen(samples.add);
      acc.emit(const AccelSample(x: 0, y: 0, z: 9.8, at: Duration.zero));
      expect(samples, hasLength(1));
      expect(acc.periods, [const Duration(milliseconds: 20)]);

      final baro = FakeBarometer();
      final readings = <PressureSample>[];
      baro.readings.listen(readings.add);
      baro.emit(const PressureSample(hPa: 1000, at: Duration.zero));
      expect(readings.single.hPa, 1000);
    },
  );

  test('FakeGpsTimeSource can lose its fix', () {
    final clock = FakeClock(DateTime.utc(2026));
    final gps = FakeGpsTimeSource(clock)..receive(DateTime.utc(2026));
    expect(gps.latest, isNotNull);
    gps.clear();
    expect(gps.latest, isNull);
  });

  test('FakeAlarmScheduler lists pending alarms', () async {
    final a = FakeAlarmScheduler(FakeClock(DateTime.utc(2026)));
    await a.schedule(7, DateTime.utc(2027));
    expect(a.pending, [7]);
  });

  test('a stopped transport leaves the network', () async {
    final world = SimWorld(start: DateTime.utc(2026), seed: 1);
    final a = world.addPhone('a', x: 0, y: 0);
    final b = world.addPhone('b', x: 10, y: 0);
    final events = <String>[];
    a.transport.peers.listen((e) => events.add('${e.peerId}:${e.connected}'));
    await a.transport.start();
    await b.transport.start();
    await b.transport.stop();
    expect(events, ['b:true', 'b:false']);
    expect(world.phones.keys, containsAll(['a', 'b']));
  });
}
