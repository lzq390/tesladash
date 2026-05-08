import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_providers.dart';
import 'pairing_controller.dart';
import 'pairing_view_model.dart';

final pairingControllerProvider = Provider<PairingController>((ref) {
  final controller = PairingController(
    bleGateway: ref.watch(bleGatewayProvider),
  );
  ref.onDispose(() {
    unawaited(controller.dispose());
  });
  return controller;
});

final pairingViewModelProvider = StreamProvider<PairingViewModel>((ref) {
  return ref.watch(pairingControllerProvider).viewModels;
});
