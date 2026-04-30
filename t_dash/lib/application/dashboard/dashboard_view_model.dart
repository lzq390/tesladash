import '../../domain/domain.dart';

class DashboardViewModel {
  const DashboardViewModel({
    required this.vehicleName,
    required this.connectionLabel,
    required this.speedText,
    required this.speedUnitText,
    required this.speedSourceLabel,
    required this.drivingLabel,
    required this.batteryLabel,
    required this.batteryProgress,
    required this.rangeLabel,
    required this.climateLabel,
    required this.tirePressureLabel,
    required this.closureLabel,
    required this.drivingModeActive,
    required this.quickControls,
  });

  factory DashboardViewModel.fromDomain({
    required VehicleState vehicle,
    required VelocitySample velocity,
    required ControlCommandService commandService,
    bool simulationAvailable = true,
  }) {
    final controlsBlockedReason = _controlBlockedReason(vehicle);

    return DashboardViewModel(
      vehicleName: vehicle.displayName,
      connectionLabel: _connectionLabel(vehicle.connectionStatus),
      speedText: velocity.kmh.round().toString(),
      speedUnitText: 'km/h',
      speedSourceLabel: _velocitySourceLabel(velocity.source),
      drivingLabel: vehicle.drivingMode.active ? '行驶中' : '停车',
      batteryLabel: _batteryLabel(vehicle.battery),
      batteryProgress: _batteryProgress(vehicle.battery),
      rangeLabel: _rangeLabel(vehicle.battery),
      climateLabel: _climateLabel(vehicle.climate),
      tirePressureLabel: _tirePressureLabel(vehicle.tirePressure),
      closureLabel: _closureLabel(vehicle.closures),
      drivingModeActive: vehicle.drivingMode.active,
      quickControls: [
        if (simulationAvailable)
          QuickControlButtonModel(
            action: QuickControlAction.toggleSimulatedDriving,
            commandType: null,
            label: vehicle.drivingMode.active ? '停止模拟' : '模拟行驶',
            enabled: true,
            disabledReason: null,
          ),
        for (final command in _primaryCommandTypes)
          QuickControlButtonModel(
            action: QuickControlAction.command,
            commandType: command,
            label: _quickControlLabel(command),
            enabled: commandService.canSend(command, vehicle),
            disabledReason: controlsBlockedReason,
          ),
      ],
    );
  }

  factory DashboardViewModel.unavailable({
    String connectionLabel = '等待车辆数据',
    String controlBlockedReason = '车辆数据不可用，无法操作',
  }) {
    return DashboardViewModel(
      vehicleName: '未连接车辆',
      connectionLabel: connectionLabel,
      speedText: '--',
      speedUnitText: 'km/h',
      speedSourceLabel: '无数据',
      drivingLabel: '停车',
      batteryLabel: '--',
      batteryProgress: 0,
      rangeLabel: '--',
      climateLabel: '空调状态未知',
      tirePressureLabel: '胎压数据暂不可用',
      closureLabel: '请确认门窗',
      drivingModeActive: false,
      quickControls: [
        for (final command in _primaryCommandTypes)
          QuickControlButtonModel(
            action: QuickControlAction.command,
            commandType: command,
            label: _quickControlLabel(command),
            enabled: false,
            disabledReason: controlBlockedReason,
          ),
      ],
    );
  }

  final String vehicleName;
  final String connectionLabel;
  final String speedText;
  final String speedUnitText;
  final String speedSourceLabel;
  final String drivingLabel;
  final String batteryLabel;
  final double batteryProgress;
  final String rangeLabel;
  final String climateLabel;
  final String tirePressureLabel;
  final String closureLabel;
  final bool drivingModeActive;
  final List<QuickControlButtonModel> quickControls;
}

enum QuickControlAction { toggleSimulatedDriving, command }

class QuickControlButtonModel {
  const QuickControlButtonModel({
    required this.action,
    required this.commandType,
    required this.label,
    required this.enabled,
    required this.disabledReason,
  });

  final QuickControlAction action;
  final ControlCommandType? commandType;
  final String label;
  final bool enabled;
  final String? disabledReason;
}

const _primaryCommandTypes = [
  ControlCommandType.unlock,
  ControlCommandType.startClimate,
  ControlCommandType.flashLights,
];

String _connectionLabel(VehicleConnectionStatus status) {
  return switch (status) {
    VehicleConnectionStatus.unpaired => '未配对',
    VehicleConnectionStatus.scanning => '正在扫描',
    VehicleConnectionStatus.connecting => '正在连接',
    VehicleConnectionStatus.connected => 'BLE 已连接',
    VehicleConnectionStatus.degraded => '连接不稳定',
    VehicleConnectionStatus.disconnected => 'BLE 已断开',
    VehicleConnectionStatus.outOfRange => '车辆不在附近',
    VehicleConnectionStatus.credentialInvalid => '配对凭证失效',
  };
}

String _velocitySourceLabel(VelocitySource source) {
  return switch (source) {
    VelocitySource.gps => 'GPS',
    VelocitySource.fusedGpsImu => 'GPS+IMU',
    VelocitySource.canBus => 'CAN',
    VelocitySource.mock => 'Mock',
  };
}

String _batteryLabel(BatteryState battery) {
  final percent = battery.stateOfChargePercent;
  if (percent == null) {
    return '--';
  }
  return '${percent.round()}%';
}

double _batteryProgress(BatteryState battery) {
  final percent = battery.stateOfChargePercent;
  if (percent == null) {
    return 0;
  }
  return percent.clamp(0, 100) / 100;
}

String _rangeLabel(BatteryState battery) {
  final range = battery.ratedRangeKm ?? battery.estimatedRangeKm;
  if (range == null) {
    return '--';
  }
  return range.round().toString();
}

String _climateLabel(ClimateState climate) {
  final setTemp = climate.setTempC?.round();
  final suffix = setTemp == null ? '' : ' $setTemp°C';

  return switch (climate.isOn) {
    true => '运行$suffix',
    false => '待机$suffix',
    null => '空调状态未知',
  };
}

String _tirePressureLabel(TirePressureState tirePressure) {
  final frontLeft = tirePressure.frontLeftBar;
  final frontRight = tirePressure.frontRightBar;

  if (frontLeft != null && frontRight != null) {
    return '${frontLeft.toStringAsFixed(1)} / ${frontRight.toStringAsFixed(1)}';
  }

  if (tirePressure.health == ProviderHealth.unavailable) {
    return '胎压数据暂不可用';
  }

  return '请确认胎压';
}

String _closureLabel(ClosureState closures) {
  return switch (closures.hasOpenItem) {
    true => '有开启项',
    false => '全部关闭',
    null => '请确认门窗',
  };
}

String _quickControlLabel(ControlCommandType type) {
  return switch (type) {
    ControlCommandType.lock => '上锁',
    ControlCommandType.unlock => '解锁',
    ControlCommandType.startClimate => '空调',
    ControlCommandType.stopClimate => '关空调',
    ControlCommandType.setClimateTemperature => '温度',
    ControlCommandType.flashLights => '闪灯',
    ControlCommandType.honk => '鸣笛',
    ControlCommandType.openFrunk => '前备箱',
    ControlCommandType.openTrunk => '后备箱',
    ControlCommandType.enableSentry => '哨兵',
    ControlCommandType.disableSentry => '关哨兵',
  };
}

String? _controlBlockedReason(VehicleState vehicle) {
  if (vehicle.drivingMode.active) {
    return '请停车后再操作';
  }
  if (!vehicle.isConnected) {
    return '车辆未连接，无法操作';
  }
  return null;
}
