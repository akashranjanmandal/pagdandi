import 'dart:typed_data';

import 'package:core_model/core_model.dart';
import 'package:meta/meta.dart';

/// A nearby phone seen by the transport.
@immutable
class PeerEvent {
  /// Creates an event.
  const PeerEvent({required this.peerId, required this.connected});

  /// Transport-level id of the peer.
  final String peerId;

  /// True when the link came up, false when it went down.
  final bool connected;
}

/// Bytes received from a peer.
@immutable
class IncomingMessage {
  /// Creates a message.
  const IncomingMessage({required this.peerId, required this.bytes});

  /// Sender at transport level.
  final String peerId;

  /// Payload.
  final Uint8List bytes;
}

/// Peer-to-peer data link (Nearby Connections).
abstract interface class Transport {
  /// Peers connecting and disconnecting.
  Stream<PeerEvent> get peers;

  /// Messages received from peers.
  Stream<IncomingMessage> get messages;

  /// Starts advertising and, if [discover] is true, discovering peers.
  /// Discovery is on demand only (battery).
  Future<void> start({bool discover = false});

  /// Stops everything.
  Future<void> stop();

  /// Sends [bytes] to all connected peers.
  Future<void> broadcast(Uint8List bytes);
}

/// What the BLE hardware supports.
@immutable
class BeaconCapabilities {
  /// Creates capabilities.
  const BeaconCapabilities({
    required this.codedPhy,
    required this.extendedAdvertising,
  });

  /// LE Coded PHY (long range) supported.
  final bool codedPhy;

  /// Extended advertising supported.
  final bool extendedAdvertising;
}

/// A beacon heard while scanning.
@immutable
class BeaconSighting {
  /// Creates a sighting.
  const BeaconSighting({required this.payload, required this.rssi});

  /// Beacon payload.
  final Uint8List payload;

  /// Signal strength in dBm.
  final int rssi;
}

/// BLE beacon for lost and SOS situations.
abstract interface class BeaconTransport {
  /// Hardware capabilities.
  BeaconCapabilities get capabilities;

  /// Beacons heard while scanning.
  Stream<BeaconSighting> get sightings;

  /// Starts broadcasting [payload]; replaces any earlier payload.
  Future<void> startBeacon(Uint8List payload);

  /// Stops broadcasting.
  Future<void> stopBeacon();

  /// Starts duty-cycled scanning.
  Future<void> startScan();

  /// Stops scanning.
  Future<void> stopScan();
}

/// SMS sending with delivery reports.
abstract interface class SmsGateway {
  /// Status updates for every message handed to [send].
  Stream<SmsReport> get reports;

  /// Hands [message] to the radio; progress arrives on [reports].
  Future<void> send(SmsMessage message);
}

/// Mobile network availability.
abstract interface class SignalMonitor {
  /// The current state.
  SignalState get current;

  /// Changes to the state.
  Stream<SignalState> get changes;
}
