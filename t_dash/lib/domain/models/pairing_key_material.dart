import 'dart:convert';

class PairingKeyMaterial {
  PairingKeyMaterial({
    required this.id,
    required this.privateKeyBase64,
    required this.publicKeySec1Base64,
    required this.createdAt,
  }) {
    _validate();
  }

  factory PairingKeyMaterial.fromJson(Map<String, Object?> json) {
    return PairingKeyMaterial(
      id: json['id'] as String,
      privateKeyBase64: json['privateKeyBase64'] as String,
      publicKeySec1Base64: json['publicKeySec1Base64'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String privateKeyBase64;
  final String publicKeySec1Base64;
  final DateTime createdAt;

  List<int> get publicKeySec1Bytes => base64Decode(publicKeySec1Base64);

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'privateKeyBase64': privateKeyBase64,
      'publicKeySec1Base64': publicKeySec1Base64,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PairingKeyMaterial(id: $id, publicKeyBytes: ${publicKeySec1Bytes.length})';
  }

  void _validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Key id cannot be empty');
    }
    if (privateKeyBase64.trim().isEmpty) {
      throw ArgumentError('Private key material cannot be empty');
    }
    final publicKey = publicKeySec1Bytes;
    if (publicKey.length != 65 || publicKey.first != 0x04) {
      throw ArgumentError(
        'Public key must be an uncompressed P-256 SEC1 point',
      );
    }
  }
}
