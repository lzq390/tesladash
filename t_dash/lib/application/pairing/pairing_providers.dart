import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_providers.dart';
import 'pairing_key_providers.dart';
import 'pairing_controller.dart';
import 'pairing_view_model.dart';
import '../../domain/domain.dart';
import '../../infrastructure/tesla_ble/tesla_ble_constants.dart';
import '../../infrastructure/tesla_ble/tesla_vehicle_pairing_service.dart';

final vehiclePairingServiceProvider = Provider<VehiclePairingService>((ref) {
  return TeslaVehiclePairingService(bleGateway: ref.watch(bleGatewayProvider));
});

final pairingControllerProvider = Provider<PairingController>((ref) {
  final controller = PairingController(
    bleGateway: ref.watch(bleGatewayProvider),
    pairingKeyRepository: ref.watch(pairingKeyRepositoryProvider),
    vehiclePairingService: ref.watch(vehiclePairingServiceProvider),
    scanServiceUuids: const [TeslaBleConstants.vehicleServiceUuid],
  );
  ref.onDispose(() {
    unawaited(controller.dispose());
  });
  return controller;
});

final pairingViewModelProvider = StreamProvider<PairingViewModel>((ref) {
  return ref.watch(pairingControllerProvider).viewModels;
});
