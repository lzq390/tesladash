import 'vehicle_enums.dart';

class VehicleState {
  const VehicleState({
    required this.vehicleId,
    required this.displayName,
    required this.connectionStatus,
    required this.updatedAt,
    required this.battery,
    required this.locks,
    required this.closures,
    required this.climate,
    required this.tirePressure,
    required this.drivingMode,
    required this.health,
  });

  final String? vehicleId;
  final String displayName;
  final VehicleConnectionStatus connectionStatus;
  final DateTime updatedAt;
  final BatteryState battery;
  final DoorLockState locks;
  final ClosureState closures;
  final ClimateState climate;
  final TirePressureState tirePressure;
  final DrivingModeState drivingMode;
  final ProviderHealth health;

  bool get isConnected =>
      connectionStatus == VehicleConnectionStatus.connected ||
      connectionStatus == VehicleConnectionStatus.degraded;

  VehicleState copyWith({
    String? vehicleId,
    String? displayName,
    VehicleConnectionStatus? connectionStatus,
    DateTime? updatedAt,
    BatteryState? battery,
    DoorLockState? locks,
    ClosureState? closures,
    ClimateState? climate,
    TirePressureState? tirePressure,
    DrivingModeState? drivingMode,
    ProviderHealth? health,
  }) {
    return VehicleState(
      vehicleId: vehicleId ?? this.vehicleId,
      displayName: displayName ?? this.displayName,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      battery: battery ?? this.battery,
      locks: locks ?? this.locks,
      closures: closures ?? this.closures,
      climate: climate ?? this.climate,
      tirePressure: tirePressure ?? this.tirePressure,
      drivingMode: drivingMode ?? this.drivingMode,
      health: health ?? this.health,
    );
  }
}

class BatteryState {
  const BatteryState({
    required this.stateOfChargePercent,
    required this.ratedRangeKm,
    required this.estimatedRangeKm,
    required this.health,
  }) : assert(
         stateOfChargePercent == null ||
             (stateOfChargePercent >= 0 && stateOfChargePercent <= 100),
       );

  final double? stateOfChargePercent;
  final double? ratedRangeKm;
  final double? estimatedRangeKm;
  final ProviderHealth health;
}

class DoorLockState {
  const DoorLockState({required this.locked, required this.health});

  final bool? locked;
  final ProviderHealth health;
}

class ClosureState {
  const ClosureState({
    required this.frontLeftDoorOpen,
    required this.frontRightDoorOpen,
    required this.rearLeftDoorOpen,
    required this.rearRightDoorOpen,
    required this.frunkOpen,
    required this.trunkOpen,
    required this.anyWindowOpen,
  });

  final bool? frontLeftDoorOpen;
  final bool? frontRightDoorOpen;
  final bool? rearLeftDoorOpen;
  final bool? rearRightDoorOpen;
  final bool? frunkOpen;
  final bool? trunkOpen;
  final bool? anyWindowOpen;

  bool? get hasOpenItem {
    final values = [
      frontLeftDoorOpen,
      frontRightDoorOpen,
      rearLeftDoorOpen,
      rearRightDoorOpen,
      frunkOpen,
      trunkOpen,
      anyWindowOpen,
    ];

    if (values.any((value) => value == true)) {
      return true;
    }
    if (values.every((value) => value == false)) {
      return false;
    }
    return null;
  }
}

class ClimateState {
  const ClimateState({
    required this.isOn,
    required this.insideTempC,
    required this.outsideTempC,
    required this.setTempC,
    required this.health,
  });

  final bool? isOn;
  final double? insideTempC;
  final double? outsideTempC;
  final double? setTempC;
  final ProviderHealth health;
}

class TirePressureState {
  const TirePressureState({
    required this.frontLeftBar,
    required this.frontRightBar,
    required this.rearLeftBar,
    required this.rearRightBar,
    required this.health,
  });

  final double? frontLeftBar;
  final double? frontRightBar;
  final double? rearLeftBar;
  final double? rearRightBar;
  final ProviderHealth health;
}

class DrivingModeState {
  const DrivingModeState({
    required this.active,
    required this.enteredAt,
    required this.reason,
  });

  final bool active;
  final DateTime? enteredAt;
  final String? reason;
}
