import '../../domain/domain.dart';

class UnavailableVehicleDataProvider implements VehicleDataProvider {
  UnavailableVehicleDataProvider({DateTime? now})
    : _state = unavailableVehicleState(now: now);

  final VehicleState _state;

  @override
  ProviderHealth get health => ProviderHealth.unavailable;

  @override
  Stream<VehicleState> get vehicleStateStream async* {
    yield _state;
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<VehicleState> refresh() async => _state;
}

VehicleState unavailableVehicleState({DateTime? now}) {
  return VehicleState(
    vehicleId: null,
    displayName: '未连接车辆',
    connectionStatus: VehicleConnectionStatus.unpaired,
    updatedAt: now ?? DateTime.now(),
    battery: const BatteryState(
      stateOfChargePercent: null,
      ratedRangeKm: null,
      estimatedRangeKm: null,
      health: ProviderHealth.unavailable,
    ),
    locks: const DoorLockState(
      locked: null,
      health: ProviderHealth.unavailable,
    ),
    closures: const ClosureState(
      frontLeftDoorOpen: null,
      frontRightDoorOpen: null,
      rearLeftDoorOpen: null,
      rearRightDoorOpen: null,
      frunkOpen: null,
      trunkOpen: null,
      anyWindowOpen: null,
    ),
    climate: const ClimateState(
      isOn: null,
      insideTempC: null,
      outsideTempC: null,
      setTempC: null,
      health: ProviderHealth.unavailable,
    ),
    tirePressure: const TirePressureState(
      frontLeftBar: null,
      frontRightBar: null,
      rearLeftBar: null,
      rearRightBar: null,
      health: ProviderHealth.unavailable,
    ),
    drivingMode: const DrivingModeState(
      active: false,
      enteredAt: null,
      reason: null,
    ),
    health: ProviderHealth.unavailable,
  );
}
