import '../../domain/domain.dart';

class MockVehiclePairingService implements VehiclePairingService {
  const MockVehiclePairingService({
    this.result = MockVehiclePairingResult.paired,
    this.stepDelay = Duration.zero,
    this.failureMessage = '模拟配对失败',
  });

  final MockVehiclePairingResult result;
  final Duration stepDelay;
  final String failureMessage;

  @override
  Stream<VehiclePairingUpdate> requestPairing({
    required String deviceId,
    required PairingKeyMaterial keyMaterial,
  }) async* {
    yield const VehiclePairingUpdate.sendingAddKeyRequest();
    if (stepDelay > Duration.zero) {
      await Future<void>.delayed(stepDelay);
    }
    yield const VehiclePairingUpdate.waitingForVehicleConfirmation();
    if (stepDelay > Duration.zero) {
      await Future<void>.delayed(stepDelay);
    }

    yield switch (result) {
      MockVehiclePairingResult.paired => const VehiclePairingUpdate.paired(),
      MockVehiclePairingResult.failed => VehiclePairingUpdate.failed(
        failureMessage,
      ),
    };
  }
}

enum MockVehiclePairingResult { paired, failed }
