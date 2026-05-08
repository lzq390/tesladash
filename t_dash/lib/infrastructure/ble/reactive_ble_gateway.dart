import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as reactive;
import 'package:permission_handler/permission_handler.dart';

import '../../domain/domain.dart';

class ReactiveBleGateway implements BleGateway {
  ReactiveBleGateway({reactive.FlutterReactiveBle? ble})
    : _ble = ble ?? reactive.FlutterReactiveBle();

  final reactive.FlutterReactiveBle _ble;

  @override
  Stream<BleAdapterStatus> get adapterStatusStream {
    return _ble.statusStream.map(_mapAdapterStatus);
  }

  @override
  Future<BleAdapterStatus> currentStatus() async {
    await _ble.initialize();
    return _mapAdapterStatus(_ble.status);
  }

  @override
  Future<bool> requestPermissions() async {
    final permissions = switch (defaultTargetPlatform) {
      TargetPlatform.android => [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ],
      TargetPlatform.iOS => [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ],
      _ => [Permission.bluetooth],
    };
    final statuses = await permissions.request();

    return statuses.values.every(_isUsablePermission);
  }

  @override
  Stream<BleDevice> scanForDevices({
    List<String> serviceUuids = const [],
    bool requireLocationServicesEnabled = false,
  }) async* {
    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      throw const BleGatewayException('蓝牙权限不可用');
    }

    final status = await currentStatus();
    if (status != BleAdapterStatus.ready) {
      throw BleGatewayException(_adapterStatusMessage(status));
    }

    yield* _ble
        .scanForDevices(
          withServices: [
            for (final serviceUuid in serviceUuids)
              reactive.Uuid.parse(serviceUuid),
          ],
          scanMode: reactive.ScanMode.lowLatency,
          requireLocationServicesEnabled: requireLocationServicesEnabled,
        )
        .map(_mapDevice);
  }

  @override
  Stream<BleConnectionUpdate> connectToDevice(
    String deviceId, {
    Duration timeout = const Duration(seconds: 12),
  }) async* {
    try {
      await for (final update in _ble.connectToDevice(
        id: deviceId,
        connectionTimeout: timeout,
      )) {
        yield _mapConnectionUpdate(update);
      }
    } catch (_) {
      yield BleConnectionUpdate(
        deviceId: deviceId,
        status: BleConnectionStatus.failed,
        message: '连接失败，请靠近车辆后重试',
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {}
}

BleAdapterStatus _mapAdapterStatus(reactive.BleStatus status) {
  return switch (status) {
    reactive.BleStatus.unknown => BleAdapterStatus.unknown,
    reactive.BleStatus.unsupported => BleAdapterStatus.unsupported,
    reactive.BleStatus.unauthorized => BleAdapterStatus.unauthorized,
    reactive.BleStatus.poweredOff => BleAdapterStatus.poweredOff,
    reactive.BleStatus.locationServicesDisabled =>
      BleAdapterStatus.locationServicesDisabled,
    reactive.BleStatus.ready => BleAdapterStatus.ready,
  };
}

BleDevice _mapDevice(reactive.DiscoveredDevice device) {
  return BleDevice(
    id: device.id,
    name: device.name,
    rssi: device.rssi,
    serviceUuids: [
      for (final serviceUuid in device.serviceUuids) serviceUuid.toString(),
    ],
    manufacturerDataHex: _toHex(device.manufacturerData),
    discoveredAt: DateTime.now(),
  );
}

BleConnectionUpdate _mapConnectionUpdate(
  reactive.ConnectionStateUpdate update,
) {
  return BleConnectionUpdate(
    deviceId: update.deviceId,
    status: switch (update.connectionState) {
      reactive.DeviceConnectionState.connecting =>
        BleConnectionStatus.connecting,
      reactive.DeviceConnectionState.connected => BleConnectionStatus.connected,
      reactive.DeviceConnectionState.disconnecting =>
        BleConnectionStatus.disconnecting,
      reactive.DeviceConnectionState.disconnected =>
        update.failure == null
            ? BleConnectionStatus.disconnected
            : BleConnectionStatus.failed,
    },
    message: update.failure == null ? null : '连接失败，请靠近车辆后重试',
    updatedAt: DateTime.now(),
  );
}

bool _isUsablePermission(PermissionStatus status) {
  return status.isGranted || status.isLimited;
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

String _toHex(List<int> values) {
  return values.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
