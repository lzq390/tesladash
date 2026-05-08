import 'dart:async';

import '../../domain/domain.dart';

class MockBleGateway implements BleGateway {
  MockBleGateway({
    List<BleDevice>? devices,
    BleAdapterStatus initialStatus = BleAdapterStatus.ready,
    this.permissionGranted = true,
    this.scanDelay = Duration.zero,
    this.connectionDelay = Duration.zero,
    this.disconnectAfterConnected = false,
    this.disconnectionDelay = Duration.zero,
  }) : _devices = List.of(devices ?? mockBleDevices()),
       _status = initialStatus;

  final List<BleDevice> _devices;
  final _statusController = StreamController<BleAdapterStatus>.broadcast();

  BleAdapterStatus _status;
  bool permissionGranted;
  Duration scanDelay;
  Duration connectionDelay;
  bool disconnectAfterConnected;
  Duration disconnectionDelay;

  @override
  Stream<BleAdapterStatus> get adapterStatusStream async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  Future<BleAdapterStatus> currentStatus() async => _status;

  @override
  Future<bool> requestPermissions() async => permissionGranted;

  @override
  Stream<BleDevice> scanForDevices({
    List<String> serviceUuids = const [],
    bool requireLocationServicesEnabled = false,
  }) async* {
    if (!permissionGranted) {
      throw const BleGatewayException('蓝牙权限不可用');
    }
    if (_status != BleAdapterStatus.ready) {
      throw BleGatewayException(_adapterStatusMessage(_status));
    }

    for (final device in _devices) {
      if (scanDelay > Duration.zero) {
        await Future<void>.delayed(scanDelay);
      }
      if (_matchesServiceFilter(device, serviceUuids)) {
        yield device;
      }
    }
  }

  @override
  Stream<BleConnectionUpdate> connectToDevice(
    String deviceId, {
    Duration timeout = const Duration(seconds: 12),
  }) async* {
    yield BleConnectionUpdate(
      deviceId: deviceId,
      status: BleConnectionStatus.connecting,
      message: null,
      updatedAt: DateTime.now(),
    );
    if (connectionDelay > Duration.zero) {
      await Future<void>.delayed(connectionDelay);
    }

    final found = _devices.any((device) => device.id == deviceId);
    yield BleConnectionUpdate(
      deviceId: deviceId,
      status: found
          ? BleConnectionStatus.connected
          : BleConnectionStatus.failed,
      message: found ? null : '未找到该蓝牙设备',
      updatedAt: DateTime.now(),
    );
    if (found && disconnectAfterConnected) {
      if (disconnectionDelay > Duration.zero) {
        await Future<void>.delayed(disconnectionDelay);
      }
      yield BleConnectionUpdate(
        deviceId: deviceId,
        status: BleConnectionStatus.disconnected,
        message: '模拟 BLE 断开',
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {}

  void updateStatus(BleAdapterStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void replaceDevices(List<BleDevice> devices) {
    _devices
      ..clear()
      ..addAll(devices);
  }

  void dispose() {
    _statusController.close();
  }
}

List<BleDevice> mockBleDevices({DateTime? now}) {
  final timestamp = now ?? DateTime.now();
  return [
    BleDevice(
      id: 'mock-tesla-ble-1',
      name: 'Tesla Model 3',
      rssi: -48,
      serviceUuids: const ['00000211-b2d1-43f0-9b88-960cebf8b91e'],
      manufacturerDataHex: '5444415348',
      discoveredAt: timestamp,
    ),
    BleDevice(
      id: 'mock-nearby-device',
      name: 'Nearby BLE Device',
      rssi: -72,
      serviceUuids: const [],
      manufacturerDataHex: '',
      discoveredAt: timestamp,
    ),
  ];
}

bool _matchesServiceFilter(BleDevice device, List<String> serviceUuids) {
  if (serviceUuids.isEmpty) {
    return true;
  }

  final advertised = device.serviceUuids
      .map((uuid) => uuid.toLowerCase())
      .toSet();
  return serviceUuids
      .map((uuid) => uuid.toLowerCase())
      .any(advertised.contains);
}

String _adapterStatusMessage(BleAdapterStatus status) {
  return switch (status) {
    BleAdapterStatus.ready => '蓝牙已就绪',
    BleAdapterStatus.unknown => '正在检查蓝牙状态',
    BleAdapterStatus.unsupported => '此设备不支持蓝牙低功耗',
    BleAdapterStatus.unauthorized => '蓝牙权限未授权',
    BleAdapterStatus.poweredOff => '请开启蓝牙',
    BleAdapterStatus.locationServicesDisabled => '请开启系统定位服务',
  };
}
