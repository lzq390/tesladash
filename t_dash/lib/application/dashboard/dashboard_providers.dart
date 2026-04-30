import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../infrastructure/mock/mock_control_command_service.dart';
import '../../infrastructure/mock/mock_dashboard_simulation_service.dart';
import '../../infrastructure/mock/mock_vehicle_data_provider.dart';
import '../../infrastructure/mock/mock_velocity_provider.dart';
import 'dashboard_simulation_service.dart';
import 'dashboard_view_model.dart';

final mockVehicleDataProvider = Provider<MockVehicleDataProvider>((ref) {
  final provider = MockVehicleDataProvider.initial();
  ref.onDispose(provider.dispose);
  return provider;
});

final mockVelocityProvider = Provider<MockVelocityProvider>((ref) {
  final provider = MockVelocityProvider.initial();
  ref.onDispose(provider.dispose);
  return provider;
});

final vehicleDataSourceProvider = Provider<VehicleDataProvider>((ref) {
  return ref.watch(mockVehicleDataProvider);
});

final velocitySourceProvider = Provider<VelocityProvider>((ref) {
  return ref.watch(mockVelocityProvider);
});

final controlCommandServiceProvider = Provider<ControlCommandService>((ref) {
  return MockControlCommandService();
});

final dashboardSimulationServiceProvider =
    Provider<DashboardSimulationService?>((ref) {
      final vehicleDataSource = ref.watch(vehicleDataSourceProvider);
      final velocitySource = ref.watch(velocitySourceProvider);

      if (vehicleDataSource is MockVehicleDataProvider &&
          velocitySource is MockVelocityProvider) {
        return MockDashboardSimulationService(
          vehicleDataProvider: vehicleDataSource,
          velocityProvider: velocitySource,
        );
      }

      return null;
    });

final vehicleStateProvider = StreamProvider<VehicleState>((ref) {
  return ref.watch(vehicleDataSourceProvider).vehicleStateStream;
});

final velocitySampleProvider = StreamProvider<VelocitySample>((ref) {
  return ref.watch(velocitySourceProvider).velocityStream;
});

final dashboardViewModelProvider = Provider<DashboardViewModel>((ref) {
  final vehicleDataSource = ref.watch(vehicleDataSourceProvider);
  final velocitySource = ref.watch(velocitySourceProvider);
  final vehicleAsync = ref.watch(vehicleStateProvider);
  final velocityAsync = ref.watch(velocitySampleProvider);
  final simulationService = ref.watch(dashboardSimulationServiceProvider);
  final vehicle = switch (vehicleDataSource) {
    MockVehicleDataProvider mock => mock.currentState,
    _ => vehicleAsync.value,
  };
  final velocity = switch (velocitySource) {
    MockVelocityProvider mock => mock.currentSample,
    _ => velocityAsync.value,
  };
  final commandService = ref.watch(controlCommandServiceProvider);

  if (vehicle == null || velocity == null) {
    final hasError = vehicleAsync.hasError || velocityAsync.hasError;
    return DashboardViewModel.unavailable(
      connectionLabel: hasError ? '数据源异常' : '等待车辆数据',
    );
  }

  return DashboardViewModel.fromDomain(
    vehicle: vehicle,
    velocity: velocity,
    commandService: commandService,
    simulationAvailable: simulationService != null,
  );
});

final dashboardControllerProvider = Provider<DashboardController>((ref) {
  return DashboardController(ref);
});

class DashboardController {
  DashboardController(this._ref);

  final Ref _ref;

  Future<void> toggleSimulatedDriving() async {
    final simulationService = _ref.read(dashboardSimulationServiceProvider);
    if (simulationService == null) {
      return;
    }

    await simulationService.toggleDriving();
    _ref.invalidate(vehicleStateProvider);
    _ref.invalidate(velocitySampleProvider);
    _ref.invalidate(dashboardViewModelProvider);
  }

  Future<ControlCommandResult> sendCommand(ControlCommandType type) {
    final vehicleState = _currentVehicleState();
    if (vehicleState == null) {
      return Future.value(
        ControlCommandResult(
          status: CommandStatus.failed,
          type: type,
          userMessage: '车辆数据不可用，无法操作',
          rawError: null,
          completedAt: DateTime.now(),
        ),
      );
    }

    final request = ControlCommandRequest(
      type: type,
      payload: const {},
      createdAt: DateTime.now(),
      requiresConfirmation: false,
    );

    return _ref.read(controlCommandServiceProvider).send(request, vehicleState);
  }

  VehicleState? _currentVehicleState() {
    final vehicleDataSource = _ref.read(vehicleDataSourceProvider);
    if (vehicleDataSource is MockVehicleDataProvider) {
      return vehicleDataSource.currentState;
    }

    return _ref.read(vehicleStateProvider).value;
  }
}
