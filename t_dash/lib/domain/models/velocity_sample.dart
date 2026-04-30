import 'vehicle_enums.dart';

class VelocitySample {
  const VelocitySample({
    required this.kmh,
    required this.timestamp,
    required this.source,
    required this.confidence,
    required this.health,
  }) : assert(kmh >= 0),
       assert(confidence >= 0 && confidence <= 1);

  final double kmh;
  final DateTime timestamp;
  final VelocitySource source;
  final double confidence;
  final ProviderHealth health;
}
