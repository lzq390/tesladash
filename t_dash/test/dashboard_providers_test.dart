import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/application/dashboard/dashboard_providers.dart';
import 'package:t_dash/application/dashboard/dashboard_view_model.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/mock_control_command_service.dart';
import 'package:t_dash/infrastructure/mock/mock_vehicle_data_provider.dart';
import 'package:t_dash/infrastructure/mock/mock_velocity_provider.dart';

void main() {
  test('dashboard controller toggles mock driving state', () async {
    final container = _mockContainer();
    addTearDown(container.dispose);

    expect(container.read(dashboardViewModelProvider).speedText, '0');
    expect(
      container.read(dashboardViewModelProvider).quickControls.first.label,
      '模拟行驶',
    );

    await container.read(dashboardControllerProvider).toggleSimulatedDriving();

    final drivingViewModel = container.read(dashboardViewModelProvider);
    expect(drivingViewModel.speedText, '42');
    expect(drivingViewModel.drivingLabel, '行驶中');
    expect(drivingViewModel.quickControls.first.label, '停止模拟');
    expect(
      drivingViewModel.quickControls
          .skip(1)
          .every((control) => !control.enabled),
      isTrue,
    );
  });

  test(
    'dashboard controller sends success and driving-mode blocked commands',
    () async {
      final container = _mockContainer();
      addTearDown(container.dispose);
      final controller = container.read(dashboardControllerProvider);

      final success = await controller.sendCommand(ControlCommandType.unlock);
      expect(success.status, CommandStatus.success);
      expect(success.userMessage, '解锁已发送');

      await controller.toggleSimulatedDriving();
      final blocked = await controller.sendCommand(ControlCommandType.unlock);
      expect(blocked.status, CommandStatus.blockedByDrivingMode);
      expect(blocked.userMessage, '请停车后再操作');
    },
  );

  test(
    'dashboard view model maps unavailable and degraded labels honestly',
    () {
      final vehicle =
          mockVehicleState(
            now: DateTime(2026),
            connectionStatus: VehicleConnectionStatus.disconnected,
            health: ProviderHealth.unavailable,
          ).copyWith(
            battery: const BatteryState(
              stateOfChargePercent: null,
              ratedRangeKm: null,
              estimatedRangeKm: null,
              health: ProviderHealth.unavailable,
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
          );

      final viewModel = DashboardViewModel.fromDomain(
        vehicle: vehicle,
        velocity: VelocitySample(
          kmh: 0,
          timestamp: DateTime(2026),
          source: VelocitySource.gps,
          confidence: 0.4,
          health: ProviderHealth.degraded,
        ),
        commandService: MockControlCommandService(),
      );

      expect(viewModel.connectionLabel, 'BLE 已断开');
      expect(viewModel.speedSourceLabel, 'GPS 弱');
      expect(viewModel.batteryLabel, '--');
      expect(viewModel.rangeLabel, '--');
      expect(viewModel.climateLabel, '空调状态未知');
      expect(viewModel.tirePressureLabel, '胎压数据暂不可用');
      expect(
        viewModel.quickControls
            .skip(1)
            .map((control) => control.disabledReason),
        everyElement('车辆未连接，无法操作'),
      );
    },
  );

  test(
    'mock provider streams emit changed vehicle and velocity states',
    () async {
      final vehicleProvider = MockVehicleDataProvider.initial(
        now: DateTime(2026),
      );
      final velocityProvider = MockVelocityProvider.initial(
        now: DateTime(2026),
      );
      addTearDown(velocityProvider.dispose);

      final vehicleFuture = vehicleProvider.vehicleStateStream.firstWhere(
        (state) => state.drivingMode.active,
      );
      final velocityFuture = velocityProvider.velocityStream.firstWhere(
        (sample) => sample.kmh == 42,
      );

      vehicleProvider.setDrivingMode(true, now: DateTime(2026, 1, 1, 0, 0, 1));
      velocityProvider.setSpeed(42, now: DateTime(2026, 1, 1, 0, 0, 1));

      expect((await vehicleFuture).drivingMode.active, isTrue);
      expect((await velocityFuture).kmh, 42);
    },
  );

  test('external sources do not fall back to mock while loading', () async {
    final container = ProviderContainer(
      overrides: [
        vehicleDataSourceProvider.overrideWithValue(
          _SilentVehicleDataProvider(),
        ),
        velocitySourceProvider.overrideWithValue(_SilentVelocityProvider()),
      ],
    );
    addTearDown(container.dispose);

    final viewModel = container.read(dashboardViewModelProvider);
    final controlLabels = viewModel.quickControls.map(
      (control) => control.label,
    );

    expect(viewModel.vehicleName, '未连接车辆');
    expect(viewModel.connectionLabel, '等待车辆数据');
    expect(viewModel.speedText, '--');
    expect(viewModel.speedSourceLabel, '无数据');
    expect(controlLabels, isNot(contains('模拟行驶')));
    expect(controlLabels, isNot(contains('停止模拟')));

    final result = await container
        .read(dashboardControllerProvider)
        .sendCommand(ControlCommandType.unlock);
    expect(result.status, CommandStatus.failed);
    expect(result.userMessage, '车辆数据不可用，无法操作');
  });

  test(
    'default dashboard keeps vehicle data honest before BLE is available',
    () async {
      final velocityProvider = _LoadedVelocityProvider();
      final container = ProviderContainer(
        overrides: [velocitySourceProvider.overrideWithValue(velocityProvider)],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        dashboardViewModelProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final vehicleSubscription = container.listen(
        vehicleStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final velocitySubscription = container.listen(
        velocitySampleProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(vehicleSubscription.close);
      addTearDown(velocitySubscription.close);
      await container.pump();
      await container.pump();
      await container.pump();

      final viewModel = container.read(dashboardViewModelProvider);
      final controlLabels = viewModel.quickControls.map(
        (control) => control.label,
      );

      expect(viewModel.vehicleName, '未连接车辆');
      expect(viewModel.connectionLabel, '未配对');
      expect(viewModel.speedText, '64');
      expect(viewModel.speedSourceLabel, 'GPS');
      expect(controlLabels, ['解锁', '空调', '闪灯']);
      expect(
        viewModel.quickControls.every((control) => !control.enabled),
        isTrue,
      );
    },
  );

  test(
    'external sources render their own values without mock simulation',
    () async {
      final vehicleProvider = _LoadedVehicleDataProvider();
      final velocityProvider = _LoadedVelocityProvider();
      final container = ProviderContainer(
        overrides: [
          vehicleDataSourceProvider.overrideWithValue(vehicleProvider),
          velocitySourceProvider.overrideWithValue(velocityProvider),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        dashboardViewModelProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final vehicleSubscription = container.listen(
        vehicleStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final velocitySubscription = container.listen(
        velocitySampleProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(vehicleSubscription.close);
      addTearDown(velocitySubscription.close);
      await container.pump();
      await container.pump();
      await container.pump();
      await container.pump();

      expect(
        container.read(vehicleStateProvider).value?.displayName,
        'Road Test',
      );
      expect(container.read(velocitySampleProvider).value?.kmh, 64);
      final viewModel = container.read(dashboardViewModelProvider);
      final controlLabels = viewModel.quickControls.map(
        (control) => control.label,
      );

      expect(viewModel.vehicleName, 'Road Test');
      expect(viewModel.connectionLabel, 'BLE 已连接');
      expect(viewModel.speedText, '64');
      expect(viewModel.speedSourceLabel, 'GPS');
      expect(controlLabels, ['解锁', '空调', '闪灯']);
    },
  );

  test('external GPS speed enters driving mode and blocks commands', () async {
    final start = DateTime(2026);
    final vehicleProvider = _LoadedVehicleDataProvider();
    final velocityProvider = _SequenceVelocityProvider([
      _velocitySample(0, start),
      _velocitySample(6, start),
      _velocitySample(6, start.add(const Duration(seconds: 3))),
    ]);
    final container = ProviderContainer(
      overrides: [
        vehicleDataSourceProvider.overrideWithValue(vehicleProvider),
        velocitySourceProvider.overrideWithValue(velocityProvider),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      dashboardViewModelProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final velocitySubscription = container.listen(
      velocitySampleProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    addTearDown(velocitySubscription.close);
    await container.pump();
    await container.pump();

    await container.pump();
    await container.pump();
    await container.pump();
    await container.pump();

    expect(
      container.read(detectedDrivingModeStoreProvider).state.active,
      isTrue,
    );
    final viewModel = container.read(dashboardViewModelProvider);
    expect(viewModel.drivingLabel, '行驶中');
    expect(
      viewModel.quickControls.every((control) => !control.enabled),
      isTrue,
    );

    final result = await container
        .read(dashboardControllerProvider)
        .sendCommand(ControlCommandType.unlock);
    expect(result.status, CommandStatus.blockedByDrivingMode);
    expect(result.userMessage, '请停车后再操作');
  });
}

ProviderContainer _mockContainer() {
  final vehicleProvider = MockVehicleDataProvider.initial(now: DateTime(2026));
  final velocityProvider = MockVelocityProvider.initial(now: DateTime(2026));
  addTearDown(vehicleProvider.dispose);
  addTearDown(velocityProvider.dispose);

  return ProviderContainer(
    overrides: [
      vehicleDataSourceProvider.overrideWithValue(vehicleProvider),
      velocitySourceProvider.overrideWithValue(velocityProvider),
    ],
  );
}

class _SilentVehicleDataProvider implements VehicleDataProvider {
  @override
  ProviderHealth get health => ProviderHealth.unavailable;

  @override
  Stream<VehicleState> get vehicleStateStream => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<VehicleState> refresh() {
    throw StateError('No vehicle state is available.');
  }
}

class _SilentVelocityProvider implements VelocityProvider {
  @override
  ProviderHealth get health => ProviderHealth.unavailable;

  @override
  VelocitySource get source => VelocitySource.gps;

  @override
  Stream<VelocitySample> get velocityStream => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class _LoadedVehicleDataProvider extends _SilentVehicleDataProvider {
  final VehicleState _state = mockVehicleState(
    now: DateTime(2026),
  ).copyWith(displayName: 'Road Test');

  @override
  ProviderHealth get health => ProviderHealth.healthy;

  @override
  Stream<VehicleState> get vehicleStateStream async* {
    yield _state;
  }

  @override
  Future<VehicleState> refresh() async => _state;
}

class _LoadedVelocityProvider extends _SilentVelocityProvider {
  final VelocitySample _sample = _velocitySample(64, DateTime(2026));

  @override
  ProviderHealth get health => ProviderHealth.healthy;

  @override
  Stream<VelocitySample> get velocityStream async* {
    yield _sample;
  }
}

class _SequenceVelocityProvider extends _SilentVelocityProvider {
  _SequenceVelocityProvider(this._samples);

  final List<VelocitySample> _samples;

  @override
  ProviderHealth get health => ProviderHealth.healthy;

  @override
  Stream<VelocitySample> get velocityStream async* {
    for (final sample in _samples) {
      yield sample;
    }
  }
}

VelocitySample _velocitySample(double kmh, DateTime timestamp) {
  return VelocitySample(
    kmh: kmh,
    timestamp: timestamp,
    source: VelocitySource.gps,
    confidence: 0.9,
    health: ProviderHealth.healthy,
  );
}
