class PairingInfo {
  const PairingInfo({
    required this.vehicleId,
    required this.displayName,
    required this.publicKeyFingerprint,
    required this.vehicleKeyId,
    required this.pairedAt,
    required this.lastConnectedAt,
  });

  final String vehicleId;
  final String displayName;
  final String publicKeyFingerprint;
  final String? vehicleKeyId;
  final DateTime pairedAt;
  final DateTime? lastConnectedAt;
}
