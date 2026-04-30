import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/application/dashboard/dashboard_view_model.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/mock_control_command_service.dart';
import 'package:t_dash/infrastructure/mock/mock_vehicle_data_provider.dart';
import 'package:t_dash/infrastructure/mock/mock_velocity_provider.dart';

void main() {
  test('maps mock domain state into dashboard labels', () {
    final viewModel = DashboardViewModel.fromDomain(
      vehicle: mockVehicleState(now: DateTime(2026)),
      velocity: mockVelocitySample(now: DateTime(2026)),
      commandService: MockControlCommandService(),
    );

    expect(viewModel.vehicleName, 'Model 3');
    expect(viewModel.connectionLabel, 'BLE 已连接');
    expect(viewModel.speedText, '0');
    expect(viewModel.speedSourceLabel, 'Mock');
    expect(viewModel.batteryLabel, '86%');
    expect(viewModel.rangeLabel, '412');
    expect(viewModel.climateLabel, '待机 22°C');
    expect(viewModel.tirePressureLabel, '2.8 / 2.8');
    expect(viewModel.quickControls.map((control) => control.label), [
      '模拟行驶',
      '解锁',
      '空调',
      '闪灯',
    ]);
  });

  test('marks command controls blocked while driving', () {
    final viewModel = DashboardViewModel.fromDomain(
      vehicle: mockVehicleState(now: DateTime(2026), drivingModeActive: true),
      velocity: mockVelocitySample(now: DateTime(2026), kmh: 42),
      commandService: MockControlCommandService(),
    );

    expect(viewModel.drivingLabel, '行驶中');
    expect(viewModel.quickControls.first.label, '停止模拟');
    expect(viewModel.quickControls.first.enabled, isTrue);
    expect(
      viewModel.quickControls.skip(1).every((control) => !control.enabled),
      isTrue,
    );
    expect(
      viewModel.quickControls.skip(1).map((control) => control.disabledReason),
      everyElement('请停车后再操作'),
    );
  });

  test(
    'mock command service can succeed, fail, and block by driving mode',
    () async {
      final service = MockControlCommandService();
      final request = ControlCommandRequest(
        type: ControlCommandType.unlock,
        payload: const {},
        createdAt: DateTime(2026),
        requiresConfirmation: false,
      );

      final success = await service.send(
        request,
        mockVehicleState(now: DateTime(2026)),
      );
      expect(success.status, CommandStatus.success);
      expect(success.userMessage, '解锁已发送');

      service.failNextCommand = true;
      final failure = await service.send(
        request,
        mockVehicleState(now: DateTime(2026)),
      );
      expect(failure.status, CommandStatus.failed);
      expect(failure.userMessage, '模拟命令失败');

      final blocked = await service.send(
        request,
        mockVehicleState(now: DateTime(2026), drivingModeActive: true),
      );
      expect(blocked.status, CommandStatus.blockedByDrivingMode);
      expect(blocked.userMessage, '请停车后再操作');
    },
  );
}
