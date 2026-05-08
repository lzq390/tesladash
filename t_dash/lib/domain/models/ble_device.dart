enum BleAdapterStatus {
  unknown,
  unsupported,
  unauthorized,
  poweredOff,
  locationServicesDisabled,
  ready,
}

enum BleConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  failed,
}

class BleDevice {
  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.serviceUuids,
    required this.manufacturerDataHex,
    required this.discoveredAt,
  });

  final String id;
  final String name;
  final int rssi;
  final List<String> serviceUuids;
  final String manufacturerDataHex;
  final DateTime discoveredAt;

  String get displayName => name.trim().isEmpty ? '未知蓝牙设备' : name;
}

class BleConnectionUpdate {
  const BleConnectionUpdate({
    required this.deviceId,
    required this.status,
    required this.message,
    required this.updatedAt,
  });

  final String deviceId;
  final BleConnectionStatus status;
  final String? message;
  final DateTime updatedAt;
}
