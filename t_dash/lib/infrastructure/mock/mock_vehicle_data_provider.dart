import 'dart:async';

import '../../domain/domain.dart';

class MockVehicleDataProvider implements VehicleDataProvider {
  MockVehicleDataProvider({required VehicleState initialState})
    : _state = initialState;

  factory MockVehicleDataProvider.initial({DateTime? now}) {
    return MockVehicleDataProvider(initialState: mockVehicleState(now: now));
  }

  final _controller = StreamController<VehicleState>.broadcast();
  VehicleState _state;

  VehicleState get currentState => _state;

  @override
  Stream<VehicleState> get vehicleStateStream async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  ProviderHealth get health => _state.health;

  @override
  Future<void> connect() async {
    updateState(
      _state.copyWith(
        connectionStatus: VehicleConnectionStatus.connected,
        health: ProviderHealth.healthy,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    updateState(
      _state.copyWith(
        connectionStatus: VehicleConnectionStatus.disconnected,
        health: ProviderHealth.unavailable,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<VehicleState> refresh() async => _state;

  void updateState(VehicleState state) {
    _state = state;
    _controller.add(_state);
  }

  void setDrivingMode(bool active, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    updateState(
      _state.copyWith(
        drivingMode: DrivingModeState(
          active: active,
          enteredAt: active ? timestamp : null,
          reason: active ? 'Mock 速度超过阈值' : null,
        ),
        updatedAt: timestamp,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}

VehicleState mockVehicleState({
  DateTime? now,
  bool drivingModeActive = false,
  VehicleConnectionStatus connectionStatus = VehicleConnectionStatus.connected,
  ProviderHealth health = ProviderHealth.healthy,
}) {
  final timestamp = now ?? DateTime.now();

  return VehicleState(
    vehicleId: 'mock-model-3',
    displayName: 'Model 3',
    connectionStatus: connectionStatus,
    updatedAt: timestamp,
    battery: const BatteryState(
      stateOfChargePercent: 86,
      ratedRangeKm: 412,
      estimatedRangeKm: 390,
      health: ProviderHealth.healthy,
    ),
    locks: const DoorLockState(locked: true, health: ProviderHealth.healthy),
    closures: const ClosureState(
      frontLeftDoorOpen: false,
      frontRightDoorOpen: false,
      rearLeftDoorOpen: false,
      rearRightDoorOpen: false,
      frunkOpen: false,
      trunkOpen: false,
      anyWindowOpen: false,
    ),
    climate: const ClimateState(
      isOn: false,
      insideTempC: 22,
      outsideTempC: 18,
      setTempC: 22,
      health: ProviderHealth.healthy,
    ),
    tirePressure: const TirePressureState(
      frontLeftBar: 2.8,
      frontRightBar: 2.8,
      rearLeftBar: 2.8,
      rearRightBar: 2.8,
      health: ProviderHealth.healthy,
    ),
    drivingMode: DrivingModeState(
      active: drivingModeActive,
      enteredAt: drivingModeActive ? timestamp : null,
      reason: drivingModeActive ? 'Mock 速度超过阈值' : null,
    ),
    health: health,
  );
}
