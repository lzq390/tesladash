import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/domain/domain.dart';

void main() {
  test('velocity sample rejects impossible values', () {
    expect(
      () => VelocitySample(
        kmh: -1,
        timestamp: DateTime(2026),
        source: VelocitySource.mock,
        confidence: 1,
        health: ProviderHealth.healthy,
      ),
      throwsAssertionError,
    );

    expect(
      () => VelocitySample(
        kmh: 0,
        timestamp: DateTime(2026),
        source: VelocitySource.mock,
        confidence: 1.2,
        health: ProviderHealth.healthy,
      ),
      throwsAssertionError,
    );
  });

  test('battery state rejects invalid state of charge', () {
    expect(
      () => BatteryState(
        stateOfChargePercent: 120,
        ratedRangeKm: 412,
        estimatedRangeKm: 390,
        health: ProviderHealth.healthy,
      ),
      throwsAssertionError,
    );
  });

  test('closure state summarizes known and unknown open items', () {
    const closed = ClosureState(
      frontLeftDoorOpen: false,
      frontRightDoorOpen: false,
      rearLeftDoorOpen: false,
      rearRightDoorOpen: false,
      frunkOpen: false,
      trunkOpen: false,
      anyWindowOpen: false,
    );
    const open = ClosureState(
      frontLeftDoorOpen: false,
      frontRightDoorOpen: true,
      rearLeftDoorOpen: false,
      rearRightDoorOpen: false,
      frunkOpen: false,
      trunkOpen: false,
      anyWindowOpen: false,
    );
    const unknown = ClosureState(
      frontLeftDoorOpen: false,
      frontRightDoorOpen: null,
      rearLeftDoorOpen: false,
      rearRightDoorOpen: false,
      frunkOpen: false,
      trunkOpen: false,
      anyWindowOpen: false,
    );

    expect(closed.hasOpenItem, isFalse);
    expect(open.hasOpenItem, isTrue);
    expect(unknown.hasOpenItem, isNull);
  });
}
