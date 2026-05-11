import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../infrastructure/security/flutter_secure_key_value_store.dart';
import '../../infrastructure/security/pointy_castle_pairing_key_service.dart';
import 'pairing_key_repository.dart';

final pairingKeyServiceProvider = Provider<PairingKeyService>((ref) {
  return PointyCastlePairingKeyService();
});

final secureKeyValueStoreProvider = Provider<SecureKeyValueStore>((ref) {
  return const FlutterSecureKeyValueStore();
});

final pairingKeyRepositoryProvider = Provider<PairingKeyRepository>((ref) {
  return PairingKeyRepository(
    keyService: ref.watch(pairingKeyServiceProvider),
    secureStore: ref.watch(secureKeyValueStoreProvider),
  );
});
