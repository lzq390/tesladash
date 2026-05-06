import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../vehicle/driving_mode_detector.dart';
import '../../infrastructure/gps/gps_velocity_provider.dart';
import '../../infrastructure/mock/mock_control_command_service.dart';
import '../../infrastructure/mock/mock_dashboard_simulation_service.dart';
import '../../infrastructure/mock/mock_vehicle_data_provider.dart';
import '../../infrastructure/mock/mock_velocity_provider.dart';
import '../../infrastructure/vehicle/unavailable_vehicle_data_provider.dart';
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

final gpsVelocityProvider = Provider<GpsVelocityProvider>((ref) {
  final provider = GpsVelocityProvider();
  ref.onDispose(() {
    unawaited(provider.stop());
  });
  return provider;
});

final unavailableVehicleDataProvider = Provider<UnavailableVehicleDataProvider>(
  (ref) {
    return UnavailableVehicleDataProvider();
  },
);

final vehicleDataSourceProvider = Provider<VehicleDataProvider>((ref) {
  return ref.watch(unavailableVehicleDataProvider);
});

final velocitySourceProvider = Provider<VelocityProvider>((ref) {
  return ref.watch(gpsVelocityProvider);
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

final drivingModeDetectorProvider = Provider<DrivingModeDetector>((ref) {
  return DrivingModeDetector();
});

final detectedDrivingModeStoreProvider = Provider<DrivingModeStateStore>((ref) {
  return DrivingModeStateStore();
});

final vehicleStateProvider = StreamProvider<VehicleState>((ref) {
  return ref.watch(vehicleDataSourceProvider).vehicleStateStream;
});

final StreamProvider<VelocitySample> velocitySampleProvider =
    StreamProvider<VelocitySample>((ref) async* {
      final velocityProvider = ref.watch(velocitySourceProvider);
      ref.onDispose(() {
        unawaited(velocityProvider.stop());
      });
      await velocityProvider.start();
      if (!ref.mounted) {
        return;
      }
      await for (final sample in velocityProvider.velocityStream) {
        if (velocityProvider is! MockVelocityProvider && ref.mounted) {
          final drivingMode = ref
              .read(drivingModeDetectorProvider)
              .update(sample);
          ref.read(detectedDrivingModeStoreProvider).state = drivingMode;
        }
        yield sample;
      }
    });

final dashboardViewModelProvider = Provider<DashboardViewModel>((ref) {
  final vehicleDataSource = ref.watch(vehicleDataSourceProvider);
  final velocitySource = ref.watch(velocitySourceProvider);
  final vehicleAsync = ref.watch(vehicleStateProvider);
  final velocityAsync = ref.watch(velocitySampleProvider);
  final simulationService = ref.watch(dashboardSimulationServiceProvider);
  final detectedDrivingMode = ref.watch(detectedDrivingModeStoreProvider).state;
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
    vehicle: _withEffectiveDrivingMode(
      vehicle,
      detectedDrivingMode,
      simulationAvailable: simulationService != null,
    ),
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
    _ref.read(drivingModeDetectorProvider).reset();
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
      final simulationAvailable =
          _ref.read(dashboardSimulationServiceProvider) != null;
      return _withEffectiveDrivingMode(
        vehicleDataSource.currentState,
        _ref.read(detectedDrivingModeStoreProvider).state,
        simulationAvailable: simulationAvailable,
      );
    }

    final vehicle = _ref.read(vehicleStateProvider).value;
    if (vehicle == null) {
      return null;
    }

    return _withEffectiveDrivingMode(
      vehicle,
      _ref.read(detectedDrivingModeStoreProvider).state,
      simulationAvailable: false,
    );
  }
}

class DrivingModeStateStore {
  DrivingModeState state = const DrivingModeState(
    active: false,
    enteredAt: null,
    reason: null,
  );
}

VehicleState _withEffectiveDrivingMode(
  VehicleState vehicle,
  DrivingModeState detectedDrivingMode, {
  required bool simulationAvailable,
}) {
  if (simulationAvailable) {
    return vehicle;
  }

  return vehicle.copyWith(drivingMode: detectedDrivingMode);
}
