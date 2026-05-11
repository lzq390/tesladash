import '../models/pairing_key_material.dart';
import '../models/vehicle_pairing.dart';

abstract interface class VehiclePairingService {
  Stream<VehiclePairingUpdate> requestPairing({
    required String deviceId,
    required PairingKeyMaterial keyMaterial,
  });
}
