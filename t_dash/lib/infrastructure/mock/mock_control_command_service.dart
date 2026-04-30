import '../../domain/domain.dart';

class MockControlCommandService implements ControlCommandService {
  MockControlCommandService({this.failNextCommand = false});

  bool failNextCommand;

  @override
  bool canSend(ControlCommandType type, VehicleState state) {
    return state.isConnected && !state.drivingMode.active;
  }

  @override
  Future<ControlCommandResult> send(
    ControlCommandRequest request,
    VehicleState state,
  ) async {
    if (state.drivingMode.active) {
      return ControlCommandResult(
        status: CommandStatus.blockedByDrivingMode,
        type: request.type,
        userMessage: '请停车后再操作',
        rawError: null,
        completedAt: DateTime.now(),
      );
    }

    if (!state.isConnected) {
      return ControlCommandResult(
        status: CommandStatus.failed,
        type: request.type,
        userMessage: '车辆未连接，无法操作',
        rawError: null,
        completedAt: DateTime.now(),
      );
    }

    if (failNextCommand) {
      failNextCommand = false;
      return ControlCommandResult(
        status: CommandStatus.failed,
        type: request.type,
        userMessage: '模拟命令失败',
        rawError: 'mock_failure',
        completedAt: DateTime.now(),
      );
    }

    return ControlCommandResult(
      status: CommandStatus.success,
      type: request.type,
      userMessage: '${_commandLabel(request.type)}已发送',
      rawError: null,
      completedAt: DateTime.now(),
    );
  }

  String _commandLabel(ControlCommandType type) {
    return switch (type) {
      ControlCommandType.lock => '上锁',
      ControlCommandType.unlock => '解锁',
      ControlCommandType.startClimate => '空调',
      ControlCommandType.stopClimate => '关闭空调',
      ControlCommandType.setClimateTemperature => '温度设置',
      ControlCommandType.flashLights => '闪灯',
      ControlCommandType.honk => '鸣笛',
      ControlCommandType.openFrunk => '前备箱',
      ControlCommandType.openTrunk => '后备箱',
      ControlCommandType.enableSentry => '哨兵模式',
      ControlCommandType.disableSentry => '关闭哨兵',
    };
  }
}
