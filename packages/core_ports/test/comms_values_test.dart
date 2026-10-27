import 'dart:typed_data';

import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';

void main() {
  test('peer events say who and whether the link is up', () {
    const e = PeerEvent(peerId: 'rahul', connected: true);
    expect(e.peerId, 'rahul');
    expect(e.connected, isTrue);
  });

  test('incoming messages carry the sender and the bytes', () {
    final m = IncomingMessage(peerId: 'a', bytes: Uint8List.fromList([1, 2]));
    expect(m.peerId, 'a');
    expect(m.bytes, [1, 2]);
  });

  test('beacon capabilities and sightings expose their fields', () {
    const c = BeaconCapabilities(codedPhy: true, extendedAdvertising: false);
    expect(c.codedPhy, isTrue);
    expect(c.extendedAdvertising, isFalse);
    final s = BeaconSighting(payload: Uint8List.fromList([9]), rssi: -80);
    expect(s.payload, [9]);
    expect(s.rssi, -80);
  });
}
