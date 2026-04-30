import 'vehicle_enums.dart';

class ControlCommandRequest {
  const ControlCommandRequest({
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.requiresConfirmation,
  });

  final ControlCommandType type;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final bool requiresConfirmation;
}

class ControlCommandResult {
  const ControlCommandResult({
    required this.status,
    required this.type,
    required this.userMessage,
    required this.rawError,
    required this.completedAt,
  });

  final CommandStatus status;
  final ControlCommandType type;
  final String userMessage;
  final Object? rawError;
  final DateTime completedAt;
}
