import 'dart:convert';

import '../../domain/domain.dart';

class PairingKeyRepository {
  PairingKeyRepository({
    required PairingKeyService keyService,
    required SecureKeyValueStore secureStore,
    String storageKey = defaultStorageKey,
  }) : _keyService = keyService,
       _secureStore = secureStore,
       _storageKey = storageKey;

  static const defaultStorageKey = 'tdash.pairing.local_key.v1';

  final PairingKeyService _keyService;
  final SecureKeyValueStore _secureStore;
  final String _storageKey;

  Future<PairingKeyMaterial> loadOrCreate({bool forceRotate = false}) async {
    if (!forceRotate) {
      final saved = await _secureStore.read(_storageKey);
      if (saved != null) {
        return PairingKeyMaterial.fromJson(
          jsonDecode(saved) as Map<String, Object?>,
        );
      }
    }

    final generated = await _keyService.generateKeyPair();
    await _secureStore.write(
      key: _storageKey,
      value: jsonEncode(generated.toJson()),
    );
    return generated;
  }

  Future<void> clear() {
    return _secureStore.delete(_storageKey);
  }
}
