import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/application/pairing/pairing_controller.dart';
import 'package:t_dash/application/pairing/pairing_key_repository.dart';
import 'package:t_dash/application/pairing/pairing_view_model.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/in_memory_secure_key_value_store.dart';
import 'package:t_dash/infrastructure/mock/mock_ble_gateway.dart';
import 'package:t_dash/infrastructure/mock/mock_vehicle_pairing_service.dart';

void main() {
  test('shows permission required when BLE permission is denied', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(permissionGranted: false),
      pairingKeyRepository: _pairingKeyRepository(),
      vehiclePairingService: _vehiclePairingService(),
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
      pairingKeyRepository: _pairingKeyRepository(),
      vehiclePairingService: _vehiclePairingService(),
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
      pairingKeyRepository: _pairingKeyRepository(),
      vehiclePairingService: _vehiclePairingService(),
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
        pairingKeyRepository: _pairingKeyRepository(),
        vehiclePairingService: _vehiclePairingService(),
        scanDuration: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.startScan();
      await controller.connect(controller.currentState.devices.first);

      expect(controller.currentState.phase, PairingPhase.paired);
      expect(controller.currentState.title, '配对成功');
    },
  );

  test('reports disconnection after a BLE connection drops', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(
        disconnectAfterConnected: true,
        disconnectionDelay: const Duration(milliseconds: 10),
      ),
      pairingKeyRepository: _pairingKeyRepository(),
      vehiclePairingService: _vehiclePairingService(
        stepDelay: const Duration(milliseconds: 50),
      ),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();
    await controller.connect(controller.currentState.devices.first);

    expect(controller.currentState.phase, PairingPhase.failed);
    expect(controller.currentState.detail, 'BLE 连接已断开，请重新扫描后再试。');

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.currentState.phase, PairingPhase.failed);
    expect(controller.currentState.detail, 'BLE 连接已断开，请重新扫描后再试。');
  });

  test(
    'does not apply BLE connection timeout to vehicle confirmation',
    () async {
      final controller = PairingController(
        bleGateway: MockBleGateway(),
        pairingKeyRepository: _pairingKeyRepository(),
        vehiclePairingService: _vehiclePairingService(
          stepDelay: const Duration(milliseconds: 30),
        ),
        scanDuration: Duration.zero,
        connectionTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      await controller.startScan();
      await controller.connect(controller.currentState.devices.first);

      expect(controller.currentState.phase, PairingPhase.paired);
      expect(controller.currentState.title, '配对成功');
    },
  );

  test(
    'keeps paired state when BLE disconnects after pairing completes',
    () async {
      final controller = PairingController(
        bleGateway: MockBleGateway(
          disconnectAfterConnected: true,
          disconnectionDelay: const Duration(milliseconds: 30),
        ),
        pairingKeyRepository: _pairingKeyRepository(),
        vehiclePairingService: _vehiclePairingService(),
        scanDuration: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.startScan();
      await controller.connect(controller.currentState.devices.first);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.currentState.phase, PairingPhase.paired);
      expect(controller.currentState.title, '配对成功');
    },
  );

  test('reports adapter unavailable state', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(initialStatus: BleAdapterStatus.poweredOff),
      pairingKeyRepository: _pairingKeyRepository(),
      vehiclePairingService: _vehiclePairingService(),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();

    expect(controller.currentState.phase, PairingPhase.failed);
    expect(controller.currentState.detail, '请开启蓝牙');
  });

  test('prepares local pairing key before scanning', () async {
    final keyService = _FakePairingKeyService();
    final controller = PairingController(
      bleGateway: MockBleGateway(),
      pairingKeyRepository: _pairingKeyRepository(keyService: keyService),
      vehiclePairingService: _vehiclePairingService(),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();

    expect(keyService.generatedCount, 1);
    expect(controller.currentState.phase, PairingPhase.devicesFound);
    expect(controller.currentState.detail, contains('本机配对密钥已准备'));
  });

  test('stops scanning when local pairing key cannot be prepared', () async {
    final controller = PairingController(
      bleGateway: MockBleGateway(),
      pairingKeyRepository: _pairingKeyRepository(
        keyService: _ThrowingPairingKeyService(),
      ),
      vehiclePairingService: _vehiclePairingService(),
      scanDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.startScan();

    expect(controller.currentState.phase, PairingPhase.failed);
    expect(controller.currentState.detail, '本地配对密钥不可用，请重试。');
    expect(controller.currentState.devices, isEmpty);
  });
}

VehiclePairingService _vehiclePairingService({
  Duration stepDelay = Duration.zero,
}) {
  return MockVehiclePairingService(stepDelay: stepDelay);
}

PairingKeyRepository _pairingKeyRepository({PairingKeyService? keyService}) {
  return PairingKeyRepository(
    keyService: keyService ?? _FakePairingKeyService(),
    secureStore: InMemorySecureKeyValueStore(),
  );
}

class _FakePairingKeyService implements PairingKeyService {
  int generatedCount = 0;

  @override
  Future<PairingKeyMaterial> generateKeyPair() async {
    generatedCount += 1;
    return PairingKeyMaterial(
      id: 'fake-$generatedCount',
      privateKeyBase64: base64Encode(List.filled(32, generatedCount)),
      publicKeySec1Base64: base64Encode([
        0x04,
        ...List.filled(64, generatedCount),
      ]),
      createdAt: DateTime(2026, 5, generatedCount),
    );
  }
}

class _ThrowingPairingKeyService implements PairingKeyService {
  @override
  Future<PairingKeyMaterial> generateKeyPair() async {
    throw StateError('local key unavailable');
  }
}
