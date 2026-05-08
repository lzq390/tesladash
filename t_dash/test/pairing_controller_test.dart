import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/application/pairing/pairing_controller.dart';
import 'package:t_dash/application/pairing/pairing_view_model.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/mock_ble_gateway.dart';

void main() {
  test('shows permission required when BLE permission is denied', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(permissionGranted: false),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();

    expect(controller.currentState.phase, PairingPhase.permissionRequired);
    expect(controller.currentState.title, '需要蓝牙权限');
  });

  test('scans and lists nearby BLE devices', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();

    expect(controller.currentState.phase, PairingPhase.devicesFound);
    expect(controller.currentState.devices, hasLength(2));
    expect(controller.currentState.primaryActionEnabled, isTrue);
  });

  test('cancelled scans do not overwrite later idle state', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(scanDelay: const Duration(milliseconds: 50)),
      scanDuration: const Duration(milliseconds: 10),
    );
    addTearDown(controller.dispose);

    final scan = controller.startScan();
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(controller.currentState.phase, PairingPhase.scanning);

    await controller.cancel();
    expect(controller.currentState.phase, PairingPhase.idle);

    await scan;
    expect(controller.currentState.phase, PairingPhase.idle);
  });

  test(
    'connects to a discovered device as BLE-only pairing placeholder',
    () async {
      final controller = PairingController(
        bleGateway: MockBleGateway(),
        scanDuration: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.startScan();
      await controller.connect(controller.currentState.devices.first);

      expect(controller.currentState.phase, PairingPhase.waitingForVehicle);
      expect(controller.currentState.title, 'BLE 已连接');
      expect(controller.currentState.detail, contains('Tesla 配对协议将在 M5 接入'));
    },
  );

  test('reports disconnection after a BLE connection drops', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(
        disconnectAfterConnected: true,
        disconnectionDelay: const Duration(milliseconds: 10),
      ),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();
    await controller.connect(controller.currentState.devices.first);

    expect(controller.currentState.phase, PairingPhase.waitingForVehicle);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.currentState.phase, PairingPhase.failed);
    expect(controller.currentState.detail, 'BLE 连接已断开，请重新扫描后再试。');
  });

  test('reports adapter unavailable state', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(initialStatus: BleAdapterStatus.poweredOff),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();

    expect(controller.currentState.phase, PairingPhase.failed);
    expect(controller.currentState.detail, '请开启蓝牙');
  });
}
