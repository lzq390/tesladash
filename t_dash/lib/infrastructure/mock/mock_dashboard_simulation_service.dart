import '../../application/dashboard/dashboard_simulation_service.dart';
import 'mock_vehicle_data_provider.dart';
import 'mock_velocity_provider.dart';

class MockDashboardSimulationService implements DashboardSimulationService {
  const MockDashboardSimulationService({
    required this.vehicleDataProvider,
    required this.velocityProvider,
  });

  final MockVehicleDataProvider vehicleDataProvider;
  final MockVelocityProvider velocityProvider;

  @override
  Future<void> toggleDriving() async {
    final nextActive = !vehicleDataProvider.currentState.drivingMode.active;

    velocityProvider.setSpeed(nextActive ? 42 : 0);
    vehicleDataProvider.setDrivingMode(nextActive);
  }
}
