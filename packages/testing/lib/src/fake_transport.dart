import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_ports/core_ports.dart';
import 'package:testing/src/sim_scheduler.dart';

/// Simulated radio medium shared by several [FakeTransport]s: range, latency,
/// jitter (reordering), loss and duplication, all driven by a seeded [Random]
/// and a [SimScheduler].
class FakeTransportNetwork {
  /// Creates a network.
  FakeTransportNetwork(
    this.sim, {
    required this.random,
    this.rangeM = 100,
    this.lossRate = 0,
    this.duplicateRate = 0,
    this.latency = const Duration(milliseconds: 50),
    this.jitter = Duration.zero,
  });

  /// Scheduler used to deliver messages.
  final SimScheduler sim;

  /// Source of randomness (inject a seeded one).
  final Random random;

  /// Maximum distance at which two nodes hear each other.
  final double rangeM;

  /// Probability that a delivery is dropped, 0 to 1.
  final double lossRate;

  /// Probability that a delivery happens twice, 0 to 1.
  final double duplicateRate;

  /// Base delivery delay.
  final Duration latency;

  /// Extra random delay up to this amount (causes reordering).
  final Duration jitter;

  final _nodes = <String, FakeTransport>{};
  final _linked = <String>{};

  /// Adds a node at ([x], [y]) metres.
  FakeTransport node(String id, {required double x, required double y}) {
    final n = FakeTransport._(this, id, x, y);
    _nodes[id] = n;
    return n;
  }

  /// Moves node [id] and emits connect/disconnect events for links that changed.
  void moveNode(String id, {required double x, required double y}) {
    final n = _nodes[id]!;
    n._x = x;
    n._y = y;
    _refreshLinks();
  }

  bool _inRange(FakeTransport a, FakeTransport b) =>
      sqrt(pow(a._x - b._x, 2) + pow(a._y - b._y, 2)) <= rangeM;

  String _key(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  void _refreshLinks() {
    for (final a in _nodes.values) {
      for (final b in _nodes.values) {
        if (a.id.compareTo(b.id) >= 0) continue;
        final up = a._running && b._running && _inRange(a, b);
        final key = _key(a.id, b.id);
        if (up && _linked.add(key)) {
          a._peers.add(PeerEvent(peerId: b.id, connected: true));
          b._peers.add(PeerEvent(peerId: a.id, connected: true));
        } else if (!up && _linked.remove(key)) {
          a._peers.add(PeerEvent(peerId: b.id, connected: false));
          b._peers.add(PeerEvent(peerId: a.id, connected: false));
        }
      }
    }
  }

  void _send(FakeTransport from, Uint8List bytes) {
    if (!from._running) return;
    for (final to in _nodes.values) {
      if (identical(to, from) || !to._running || !_inRange(from, to)) continue;
      if (random.nextDouble() < lossRate) continue;
      final copies = random.nextDouble() < duplicateRate ? 2 : 1;
      for (var i = 0; i < copies; i++) {
        final extra = jitter == Duration.zero
            ? Duration.zero
            : Duration(microseconds: random.nextInt(jitter.inMicroseconds + 1));
        sim.after(latency + extra, () {
          if (to._running) {
            to._messages.add(IncomingMessage(peerId: from.id, bytes: bytes));
          }
        });
      }
    }
  }
}

/// One phone's [Transport] on a [FakeTransportNetwork].
class FakeTransport implements Transport {
  FakeTransport._(this._net, this.id, this._x, this._y);

  final FakeTransportNetwork _net;

  /// Transport-level id.
  final String id;
  double _x;
  double _y;
  bool _running = false;
  final _peers = StreamController<PeerEvent>.broadcast(sync: true);
  final _messages = StreamController<IncomingMessage>.broadcast(sync: true);

  @override
  Stream<PeerEvent> get peers => _peers.stream;

  @override
  Stream<IncomingMessage> get messages => _messages.stream;

  @override
  Future<void> start({bool discover = false}) async {
    _running = true;
    _net._refreshLinks();
  }

  @override
  Future<void> stop() async {
    _running = false;
    _net._refreshLinks();
  }

  @override
  Future<void> broadcast(Uint8List bytes) async => _net._send(this, bytes);
}
