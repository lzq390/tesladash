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

  Future<void> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    bool withResponse = false,
  });

  BleCharacteristicNotifications subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  });

  Future<void> disconnect(String deviceId);
}

class BleCharacteristicNotifications {
  const BleCharacteristicNotifications({
    required this.stream,
    required this.ready,
  });

  final Stream<List<int>> stream;
  final Future<void> ready;
}

class BleGatewayException implements Exception {
  const BleGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}
