import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../infrastructure/ble/reactive_ble_gateway.dart';

final bleGatewayProvider = Provider<BleGateway>((ref) {
  return ReactiveBleGateway();
});
