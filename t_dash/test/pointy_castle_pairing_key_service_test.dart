import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/infrastructure/security/pointy_castle_pairing_key_service.dart';

void main() {
  test('generates exportable P-256 key material for vehicle pairing', () async {
    final service = PointyCastlePairingKeyService();

    final key = await service.generateKeyPair();
    final privateKey = base64Decode(key.privateKeyBase64);
    final publicKey = key.publicKeySec1Bytes;

    expect(key.id, startsWith('p256-'));
    expect(privateKey, hasLength(32));
    expect(publicKey, hasLength(65));
    expect(publicKey.first, 0x04);
    expect(key.toString(), isNot(contains(key.privateKeyBase64)));
  });
}
