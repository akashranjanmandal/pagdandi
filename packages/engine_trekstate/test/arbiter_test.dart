import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:test/test.dart';

void main() {
  test('no demands means no hardware is requested', () {
    final r = ResourceArbiter.merge(const []);
    expect(r.location, isNull);
    expect(r.accelerometerPeriod, isNull);
    expect(r.barometer, isFalse);
    expect(r.motion, isFalse);
    expect(r.discovery, isFalse);
  });

  test('the fastest GPS interval wins', () {
    final r = ResourceArbiter.merge(const [
      Demand(gpsInterval: Duration(seconds: 30), allowBatching: true),
      Demand(gpsInterval: Duration(seconds: 5)),
    ]);
    expect(r.location!.interval, const Duration(seconds: 5));
  });

  test('batching is allowed only if every GPS demand allows it', () {
    final all = ResourceArbiter.merge(const [
      Demand(
        gpsInterval: Duration(seconds: 30),
        allowBatching: true,
        maxBatchDelay: Duration(minutes: 2),
      ),
      Demand(
        gpsInterval: Duration(seconds: 10),
        allowBatching: true,
        maxBatchDelay: Duration(minutes: 1),
      ),
    ]);
    expect(all.location!.maxBatchDelay, const Duration(minutes: 1));
    final one = ResourceArbiter.merge(const [
      Demand(
        gpsInterval: Duration(seconds: 30),
        allowBatching: true,
        maxBatchDelay: Duration(minutes: 2),
      ),
      Demand(gpsInterval: Duration(seconds: 5)),
    ]);
    expect(one.location!.maxBatchDelay, Duration.zero);
  });

  test('demands without GPS do not stop batching for those that want it', () {
    final r = ResourceArbiter.merge(const [
      Demand(barometer: true),
      Demand(
        gpsInterval: Duration(seconds: 30),
        allowBatching: true,
        maxBatchDelay: Duration(minutes: 2),
      ),
    ]);
    expect(r.location!.maxBatchDelay, const Duration(minutes: 2));
    expect(r.barometer, isTrue);
  });

  test('the fastest accelerometer period wins; sensors are or-ed', () {
    final r = ResourceArbiter.merge(const [
      Demand(accelerometerPeriod: Duration(milliseconds: 100), motion: true),
      Demand(accelerometerPeriod: Duration(milliseconds: 20), discovery: true),
    ]);
    expect(r.accelerometerPeriod, const Duration(milliseconds: 20));
    expect(r.motion, isTrue);
    expect(r.discovery, isTrue);
  });

  test('a GPS demand with batching but no delay defaults to live delivery', () {
    final r = ResourceArbiter.merge(const [
      Demand(gpsInterval: Duration(seconds: 10), allowBatching: true),
    ]);
    expect(r.location!.maxBatchDelay, Duration.zero);
  });

  test('requests compare by value', () {
    const a = [Demand(gpsInterval: Duration(seconds: 5))];
    expect(ResourceArbiter.merge(a), ResourceArbiter.merge(a));
    expect(
      ResourceArbiter.merge(a).hashCode,
      ResourceArbiter.merge(a).hashCode,
    );
    expect(
      ResourceArbiter.merge(a),
      isNot(ResourceArbiter.merge(const [Demand(barometer: true)])),
    );
  });
}
