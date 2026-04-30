import 'dart:async';

import '../../domain/domain.dart';

class MockVelocityProvider implements VelocityProvider {
  MockVelocityProvider({required VelocitySample initialSample})
    : _sample = initialSample;

  factory MockVelocityProvider.initial({DateTime? now}) {
    return MockVelocityProvider(initialSample: mockVelocitySample(now: now));
  }

  final _controller = StreamController<VelocitySample>.broadcast();
  VelocitySample _sample;
  bool _started = false;

  VelocitySample get currentSample => _sample;

  @override
  Stream<VelocitySample> get velocityStream async* {
    yield _sample;
    yield* _controller.stream;
  }

  @override
  VelocitySource get source => _sample.source;

  @override
  ProviderHealth get health => _sample.health;

  @override
  Future<void> start() async {
    _started = true;
  }

  @override
  Future<void> stop() async {
    _started = false;
  }

  void setSpeed(double kmh, {DateTime? now}) {
    emit(
      VelocitySample(
        kmh: kmh,
        timestamp: now ?? DateTime.now(),
        source: VelocitySource.mock,
        confidence: _started ? 1 : 0.8,
        health: ProviderHealth.healthy,
      ),
    );
  }

  void emit(VelocitySample sample) {
    _sample = sample;
    _controller.add(_sample);
  }

  void dispose() {
    _controller.close();
  }
}

VelocitySample mockVelocitySample({DateTime? now, double kmh = 0}) {
  return VelocitySample(
    kmh: kmh,
    timestamp: now ?? DateTime.now(),
    source: VelocitySource.mock,
    confidence: 1,
    health: ProviderHealth.healthy,
  );
}
