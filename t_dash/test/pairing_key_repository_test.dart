import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/application/pairing/pairing_key_repository.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/in_memory_secure_key_value_store.dart';

void main() {
  test(
    'loadOrCreate stores and reuses generated pairing key material',
    () async {
      final keyService = _FakePairingKeyService();
      final store = InMemorySecureKeyValueStore();
      final repository = PairingKeyRepository(
        keyService: keyService,
        secureStore: store,
      );

      final first = await repository.loadOrCreate();
      final second = await repository.loadOrCreate();

      expect(first.id, second.id);
      expect(keyService.generatedCount, 1);
      expect(first.toString(), isNot(contains(first.privateKeyBase64)));
    },
  );

  test('forceRotate replaces stored pairing key material', () async {
    final keyService = _FakePairingKeyService();
    final store = InMemorySecureKeyValueStore();
    final repository = PairingKeyRepository(
      keyService: keyService,
      secureStore: store,
    );

    final first = await repository.loadOrCreate();
    final second = await repository.loadOrCreate(forceRotate: true);

    expect(first.id, isNot(second.id));
    expect(keyService.generatedCount, 2);
  });

  test('clear removes persisted pairing key material', () async {
    final keyService = _FakePairingKeyService();
    final store = InMemorySecureKeyValueStore();
    final repository = PairingKeyRepository(
      keyService: keyService,
      secureStore: store,
    );

    await repository.loadOrCreate();
    await repository.clear();
    await repository.loadOrCreate();

    expect(keyService.generatedCount, 2);
  });
}

class _FakePairingKeyService implements PairingKeyService {
  int generatedCount = 0;

  @override
  Future<PairingKeyMaterial> generateKeyPair() async {
    generatedCount += 1;
    return PairingKeyMaterial(
      id: 'fake-$generatedCount',
      privateKeyBase64: base64Encode(List.filled(32, generatedCount)),
      publicKeySec1Base64: base64Encode([
        0x04,
        ...List.filled(64, generatedCount),
      ]),
      createdAt: DateTime(2026, 5, generatedCount),
    );
  }
}
