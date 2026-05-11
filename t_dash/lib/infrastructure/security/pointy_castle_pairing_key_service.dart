import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

import '../../domain/domain.dart';

class PointyCastlePairingKeyService implements PairingKeyService {
  PointyCastlePairingKeyService({
    pc.ECDomainParameters? domainParameters,
    pc.SecureRandom Function()? randomFactory,
  }) : _domainParameters =
           domainParameters ?? pc.ECDomainParameters('prime256v1'),
       _randomFactory = randomFactory ?? _createSecureRandom;

  final pc.ECDomainParameters _domainParameters;
  final pc.SecureRandom Function() _randomFactory;

  @override
  Future<PairingKeyMaterial> generateKeyPair() async {
    final generator = pc.ECKeyGenerator()
      ..init(
        pc.ParametersWithRandom(
          pc.ECKeyGeneratorParameters(_domainParameters),
          _randomFactory(),
        ),
      );
    final keyPair = generator.generateKeyPair();
    final privateKey = keyPair.privateKey;
    final publicKey = keyPair.publicKey;
    final privateD = privateKey.d;
    final publicPoint = publicKey.Q;

    if (privateD == null || publicPoint == null) {
      throw StateError('Generated P-256 key pair is incomplete.');
    }

    final now = DateTime.now();
    return PairingKeyMaterial(
      id: 'p256-${now.microsecondsSinceEpoch}',
      privateKeyBase64: base64Encode(_bigIntToFixedLengthBytes(privateD, 32)),
      publicKeySec1Base64: base64Encode(
        _normalizeP256PublicKey(publicPoint.getEncoded(false)),
      ),
      createdAt: now,
    );
  }
}

pc.SecureRandom _createSecureRandom() {
  final random = Random.secure();
  final seed = Uint8List(32);
  for (var i = 0; i < seed.length; i += 1) {
    seed[i] = random.nextInt(256);
  }

  return pc.FortunaRandom()..seed(pc.KeyParameter(seed));
}

List<int> _bigIntToFixedLengthBytes(BigInt value, int length) {
  final hex = value.toRadixString(16).padLeft(length * 2, '0');
  if (hex.length > length * 2) {
    throw StateError('P-256 private key is longer than $length bytes.');
  }

  return List<int>.generate(
    length,
    (index) => int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16),
    growable: false,
  );
}

List<int> _normalizeP256PublicKey(List<int> bytes) {
  if (bytes.length == 65 && bytes.first == 0x04) {
    return List.unmodifiable(bytes);
  }
  throw StateError('Unexpected P-256 public key length: ${bytes.length}');
}
