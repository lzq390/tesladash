import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/mock_ble_gateway.dart';

void main() {
  test('scans mock BLE devices and filters by service UUID', () async {
    final gateway = MockBleGateway();

    final devices = await gateway
        .scanForDevices(
          serviceUuids: const ['00000211-b2d1-43f0-9b88-960cebf8b91e'],
        )
        .toList();

    expect(devices, hasLength(1));
    expect(devices.single.displayName, 'Tesla Model 3');
  });

  test('reports permission and adapter failures honestly', () async {
    final permissionGateway = MockBleGateway(permissionGranted: false);

    expect(
      permissionGateway.scanForDevices().drain<void>(),
      throwsA(isA<BleGatewayException>()),
    );

    final poweredOffGateway = MockBleGateway(
      initialStatus: BleAdapterStatus.poweredOff,
    );
    expect(
      poweredOffGateway.scanForDevices().drain<void>(),
      throwsA(isA<BleGatewayException>()),
    );
  });

  test('connects known mock devices and fails unknown devices', () async {
    final gateway = MockBleGateway();

    final known = await gateway.connectToDevice('mock-tesla-ble-1').toList();
    expect(known.map((event) => event.status), [
      BleConnectionStatus.connecting,
      BleConnectionStatus.connected,
    ]);

    final unknown = await gateway.connectToDevice('missing-device').toList();
    expect(unknown.last.status, BleConnectionStatus.failed);
    expect(unknown.last.message, '未找到该蓝牙设备');
  });
}
