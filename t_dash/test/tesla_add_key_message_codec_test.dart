import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/mock_ble_gateway.dart';
import 'package:t_dash/infrastructure/tesla_ble/tesla_add_key_message_codec.dart';
import 'package:t_dash/infrastructure/tesla_ble/tesla_ble_constants.dart';
import 'package:t_dash/infrastructure/tesla_ble/tesla_vehicle_pairing_service.dart';

void main() {
  test('builds length-framed add-key envelope with raw public key', () {
    const codec = TeslaAddKeyMessageCodec();
    final key = _fakeKeyMaterial();

    final envelope = codec.buildAddKeyEnvelope(key);
    final chunks = codec.chunks(envelope, chunkSize: 20);
    final framedLength = chunks.expand((chunk) => chunk).length;

    expect(envelope.length, lessThan(TeslaBleConstants.maxMessageSize));
    expect(framedLength, envelope.length + 2);
    expect(_containsSublist(envelope, key.publicKeySec1Bytes), isTrue);
    expect(chunks.length, greaterThan(1));
  });

  test('decodes whitelist operation success and failure responses', () {
    const codec = TeslaAddKeyMessageCodec();

    final success = codec.decodePairingResponse(
      _fromVcsecCommandStatus(whitelistInformation: 0, operationStatus: 0),
    );
    final failure = codec.decodePairingResponse(
      _fromVcsecCommandStatus(whitelistInformation: 24, operationStatus: 2),
    );

    expect(success.status, TeslaPairingResponseStatus.paired);
    expect(failure.status, TeslaPairingResponseStatus.failed);
    expect(failure.message, contains('拒绝'));
  });

  test('sends add-key request over Tesla BLE characteristics', () async {
    const codec = TeslaAddKeyMessageCodec();
    final gateway = MockBleGateway();
    addTearDown(gateway.dispose);
    final service = TeslaVehiclePairingService(
      bleGateway: gateway,
      codec: codec,
      responseTimeout: const Duration(milliseconds: 500),
      chunkSize: 20,
    );

    final updatesFuture = service
        .requestPairing(
          deviceId: 'mock-tesla-ble-1',
          keyMaterial: _fakeKeyMaterial(),
        )
        .toList();

    await Future<void>.delayed(const Duration(milliseconds: 10));
    gateway.emitNotification(
      deviceId: 'mock-tesla-ble-1',
      serviceUuid: TeslaBleConstants.vehicleServiceUuid,
      characteristicUuid: TeslaBleConstants.fromVehicleUuid,
      value: codec.frame(
        _fromVcsecCommandStatus(whitelistInformation: 0, operationStatus: 0),
      ),
    );

    final updates = await updatesFuture;

    expect(gateway.writtenCharacteristics, isNotEmpty);
    expect(
      gateway.writtenCharacteristics.every(
        (write) =>
            write.serviceUuid == TeslaBleConstants.vehicleServiceUuid &&
            write.characteristicUuid == TeslaBleConstants.toVehicleUuid,
      ),
      isTrue,
    );
    expect(updates.map((update) => update.step), [
      VehiclePairingStep.sendingAddKeyRequest,
      VehiclePairingStep.waitingForVehicleConfirmation,
      VehiclePairingStep.paired,
    ]);
  });

  test(
    'waits for notification subscription readiness before writing add-key',
    () async {
      const codec = TeslaAddKeyMessageCodec();
      final gateway = MockBleGateway(
        notificationReadyDelay: const Duration(milliseconds: 40),
      );
      addTearDown(gateway.dispose);
      final service = TeslaVehiclePairingService(
        bleGateway: gateway,
        codec: codec,
        responseTimeout: const Duration(milliseconds: 500),
      );

      final updatesFuture = service
          .requestPairing(
            deviceId: 'mock-tesla-ble-1',
            keyMaterial: _fakeKeyMaterial(),
          )
          .toList();

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(gateway.writtenCharacteristics, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(gateway.writtenCharacteristics, isNotEmpty);
      gateway.emitNotification(
        deviceId: 'mock-tesla-ble-1',
        serviceUuid: TeslaBleConstants.vehicleServiceUuid,
        characteristicUuid: TeslaBleConstants.fromVehicleUuid,
        value: codec.frame(
          _fromVcsecCommandStatus(whitelistInformation: 0, operationStatus: 0),
        ),
      );

      final updates = await updatesFuture;

      expect(
        updates.map((update) => update.step).last,
        VehiclePairingStep.paired,
      );
    },
  );
}

PairingKeyMaterial _fakeKeyMaterial() {
  return PairingKeyMaterial(
    id: 'fake',
    privateKeyBase64: base64Encode(List.filled(32, 9)),
    publicKeySec1Base64: base64Encode([0x04, ...List.generate(64, (i) => i)]),
    createdAt: DateTime(2026, 5, 9),
  );
}

List<int> _fromVcsecCommandStatus({
  required int whitelistInformation,
  required int operationStatus,
}) {
  final whitelistStatus = [8, whitelistInformation, 24, operationStatus];
  final commandStatus = [
    8,
    operationStatus,
    26,
    whitelistStatus.length,
    ...whitelistStatus,
  ];
  return [34, commandStatus.length, ...commandStatus];
}

bool _containsSublist(List<int> source, List<int> pattern) {
  for (var i = 0; i <= source.length - pattern.length; i += 1) {
    var matched = true;
    for (var j = 0; j < pattern.length; j += 1) {
      if (source[i + j] != pattern[j]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      return true;
    }
  }
  return false;
}
