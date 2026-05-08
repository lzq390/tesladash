import '../models/ble_device.dart';

abstract interface class BleGateway {
  Stream<BleAdapterStatus> get adapterStatusStream;

  Future<BleAdapterStatus> currentStatus();

  Future<bool> requestPermissions();

  Stream<BleDevice> scanForDevices({
    List<String> serviceUuids = const [],
    bool requireLocationServicesEnabled = false,
  });

  Stream<BleConnectionUpdate> connectToDevice(
    String deviceId, {
    Duration timeout = const Duration(seconds: 12),
  });

  Future<void> disconnect(String deviceId);
}

class BleGatewayException implements Exception {
  const BleGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}
