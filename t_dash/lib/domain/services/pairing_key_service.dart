import '../models/pairing_key_material.dart';

abstract interface class PairingKeyService {
  Future<PairingKeyMaterial> generateKeyPair();
}
