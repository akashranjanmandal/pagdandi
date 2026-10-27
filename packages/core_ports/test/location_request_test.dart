import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';

void main() {
  test('a request delivers live and unfiltered unless told otherwise', () {
    const r = LocationRequest(interval: Duration(seconds: 5));
    expect(r.interval, const Duration(seconds: 5));
    expect(r.maxBatchDelay, Duration.zero);
    expect(r.minDistanceM, 0);
  });

  test('a request can allow batching and a minimum distance', () {
    const r = LocationRequest(
      interval: Duration(seconds: 30),
      maxBatchDelay: Duration(minutes: 2),
      minDistanceM: 10,
    );
    expect(r.maxBatchDelay, const Duration(minutes: 2));
    expect(r.minDistanceM, 10);
  });
}
