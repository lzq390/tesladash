import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/application/vehicle/driving_mode_detector.dart';
import 'package:t_dash/domain/domain.dart';

void main() {
  test('enters driving mode after sustained speed above threshold', () {
    final detector = DrivingModeDetector();
    final start = DateTime(2026);

    expect(detector.update(_sample(6, start)).active, isFalse);
    expect(
      detector.update(_sample(6, start.add(const Duration(seconds: 2)))).active,
      isFalse,
    );

    final drivingMode = detector.update(
      _sample(6, start.add(const Duration(seconds: 3))),
    );
    expect(drivingMode.active, isTrue);
    expect(drivingMode.reason, 'GPS 速度超过 5 km/h');
  });

  test('exits driving mode after sustained speed below threshold', () {
    final detector = DrivingModeDetector();
    final start = DateTime(2026);

    detector.update(_sample(8, start));
    detector.update(_sample(8, start.add(const Duration(seconds: 3))));

    expect(
      detector.update(_sample(0, start.add(const Duration(seconds: 4)))).active,
      isTrue,
    );
    expect(
      detector.update(_sample(0, start.add(const Duration(seconds: 9)))).active,
      isFalse,
    );
    expect(detector.state.enteredAt, isNull);
  });

  test('ignores unavailable velocity samples', () {
    final detector = DrivingModeDetector();
    final start = DateTime(2026);

    detector.update(_sample(8, start, health: ProviderHealth.unavailable));
    detector.update(
      _sample(
        8,
        start.add(const Duration(seconds: 10)),
        health: ProviderHealth.unavailable,
      ),
    );

    expect(detector.state.active, isFalse);
  });
}

VelocitySample _sample(
  double kmh,
  DateTime timestamp, {
  ProviderHealth health = ProviderHealth.healthy,
}) {
  return VelocitySample(
    kmh: kmh,
    timestamp: timestamp,
    source: VelocitySource.gps,
    confidence: health == ProviderHealth.unavailable ? 0 : 1,
    health: health,
  );
}
