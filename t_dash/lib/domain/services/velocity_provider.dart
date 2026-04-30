import '../models/vehicle_enums.dart';
import '../models/velocity_sample.dart';

abstract interface class VelocityProvider {
  Stream<VelocitySample> get velocityStream;
  VelocitySource get source;
  ProviderHealth get health;

  Future<void> start();
  Future<void> stop();
}
