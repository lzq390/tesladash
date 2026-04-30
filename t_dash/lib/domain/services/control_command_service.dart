import '../models/control_command.dart';
import '../models/vehicle_enums.dart';
import '../models/vehicle_state.dart';

abstract interface class ControlCommandService {
  Future<ControlCommandResult> send(
    ControlCommandRequest request,
    VehicleState state,
  );

  bool canSend(ControlCommandType type, VehicleState state);
}
