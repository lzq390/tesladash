import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../domain/domain.dart';
import 'location_gateway.dart';

class GpsVelocityProvider implements VelocityProvider {
  GpsVelocityProvider({
    LocationGateway gateway = const GeolocatorLocationGateway(),
    LocationSettings settings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    ),
  }) : _gateway = gateway,
       _settings = settings;

  final LocationGateway _gateway;
  final LocationSettings _settings;
  final _controller = StreamController<VelocitySample>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  VelocitySample _currentSample = _unavailableSample();
  ProviderHealth _health = ProviderHealth.unavailable;
  bool _started = false;

  @override
  Stream<VelocitySample> get velocityStream async* {
    yield _currentSample;
    yield* _controller.stream;
  }

  @override
  VelocitySource get source => VelocitySource.gps;

  @override
  ProviderHealth get health => _health;

  @override
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    final serviceEnabled = await _gateway.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _emitUnavailable();
      _started = false;
      return;
    }

    var permission = await _gateway.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _gateway.requestPermission();
    }

    if (!_isUsablePermission(permission)) {
      _emitUnavailable();
      _started = false;
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = _gateway
        .getPositionStream(settings: _settings)
        .listen(_handlePosition, onError: _handleStreamError);
  }

  @override
  Future<void> stop() async {
    _started = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _handlePosition(Position position) {
    final health = _healthFor(position);
    final speedMps = math.max(0.0, position.speed);
    final confidence = _confidenceFor(position, health);

    _emit(
      VelocitySample(
        kmh: speedMps * 3.6,
        timestamp: position.timestamp,
        source: VelocitySource.gps,
        confidence: confidence,
        health: health,
      ),
    );
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    final subscription = _positionSubscription;
    _positionSubscription = null;
    _started = false;
    _emitUnavailable();
    unawaited(subscription?.cancel() ?? Future<void>.value());
  }

  void _emitUnavailable() {
    _emit(_unavailableSample());
  }

  void _emit(VelocitySample sample) {
    _currentSample = sample;
    _health = sample.health;
    if (!_controller.isClosed) {
      _controller.add(sample);
    }
  }

  ProviderHealth _healthFor(Position position) {
    if (position.isMocked) {
      return ProviderHealth.degraded;
    }
    if (position.accuracy > 50 || position.speedAccuracy > 5) {
      return ProviderHealth.degraded;
    }
    return ProviderHealth.healthy;
  }

  double _confidenceFor(Position position, ProviderHealth health) {
    if (health == ProviderHealth.unavailable) {
      return 0;
    }

    final speedAccuracyPenalty = (position.speedAccuracy / 5).clamp(0.0, 1.0);
    final horizontalAccuracyPenalty = (position.accuracy / 50).clamp(0.0, 1.0);
    final confidence =
        1 - math.max(speedAccuracyPenalty, horizontalAccuracyPenalty);

    return confidence.clamp(0.2, 1.0).toDouble();
  }

  static bool _isUsablePermission(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static VelocitySample _unavailableSample() {
    return VelocitySample(
      kmh: 0,
      timestamp: DateTime.now(),
      source: VelocitySource.gps,
      confidence: 0,
      health: ProviderHealth.unavailable,
    );
  }
}
