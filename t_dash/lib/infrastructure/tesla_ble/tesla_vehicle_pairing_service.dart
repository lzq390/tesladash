import 'dart:async';

import '../../domain/domain.dart';
import 'tesla_add_key_message_codec.dart';
import 'tesla_ble_constants.dart';

class TeslaVehiclePairingService implements VehiclePairingService {
  TeslaVehiclePairingService({
    required BleGateway bleGateway,
    TeslaAddKeyMessageCodec codec = const TeslaAddKeyMessageCodec(),
    Duration responseTimeout = const Duration(seconds: 90),
    int chunkSize = TeslaBleConstants.defaultChunkSize,
  }) : _bleGateway = bleGateway,
       _codec = codec,
       _responseTimeout = responseTimeout,
       _chunkSize = chunkSize;

  final BleGateway _bleGateway;
  final TeslaAddKeyMessageCodec _codec;
  final Duration _responseTimeout;
  final int _chunkSize;

  @override
  Stream<VehiclePairingUpdate> requestPairing({
    required String deviceId,
    required PairingKeyMaterial keyMaterial,
  }) async* {
    final assembler = TeslaBleFrameAssembler();
    final responses = StreamController<TeslaPairingResponse>();
    StreamSubscription<List<int>>? subscription;

    try {
      final notifications = _bleGateway.subscribeToCharacteristic(
        deviceId: deviceId,
        serviceUuid: TeslaBleConstants.vehicleServiceUuid,
        characteristicUuid: TeslaBleConstants.fromVehicleUuid,
      );
      subscription = notifications.stream.listen((chunk) {
        for (final payload in assembler.addChunk(chunk)) {
          responses.add(_codec.decodePairingResponse(payload));
        }
      }, onError: responses.addError);

      yield const VehiclePairingUpdate.sendingAddKeyRequest();
      await notifications.ready;

      final envelope = _codec.buildAddKeyEnvelope(keyMaterial);
      for (final chunk in _codec.chunks(envelope, chunkSize: _chunkSize)) {
        await _bleGateway.writeCharacteristic(
          deviceId: deviceId,
          serviceUuid: TeslaBleConstants.vehicleServiceUuid,
          characteristicUuid: TeslaBleConstants.toVehicleUuid,
          value: chunk,
        );
      }

      yield const VehiclePairingUpdate.waitingForVehicleConfirmation();

      final response = await responses.stream
          .firstWhere(
            (item) => item.status != TeslaPairingResponseStatus.waiting,
          )
          .timeout(_responseTimeout);

      yield switch (response.status) {
        TeslaPairingResponseStatus.paired =>
          const VehiclePairingUpdate.paired(),
        TeslaPairingResponseStatus.failed => VehiclePairingUpdate.failed(
          response.message ?? '车辆拒绝配对请求。',
        ),
        TeslaPairingResponseStatus.waiting =>
          const VehiclePairingUpdate.waitingForVehicleConfirmation(),
      };
    } on TimeoutException {
      yield const VehiclePairingUpdate.failed('等待车机确认超时，请重试。');
    } on Object {
      yield const VehiclePairingUpdate.failed('发送配对请求失败，请靠近车辆后重试。');
    } finally {
      await subscription?.cancel();
      await responses.close();
    }
  }
}
