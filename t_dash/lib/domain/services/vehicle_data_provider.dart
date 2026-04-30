import '../models/vehicle_enums.dart';
import '../models/vehicle_state.dart';

abstract interface class VehicleDataProvider {
  Stream<VehicleState> get vehicleStateStream;
  ProviderHealth get health;

  Future<void> connect();
  Future<void> disconnect();
  Future<VehicleState> refresh();
}
