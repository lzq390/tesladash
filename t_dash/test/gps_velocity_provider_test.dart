import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/gps/gps_velocity_provider.dart';
import 'package:t_dash/infrastructure/gps/location_gateway.dart';

void main() {
  test('emits unavailable when location service is disabled', () async {
    final provider = GpsVelocityProvider(
      gateway: _FakeLocationGateway(serviceEnabled: false),
    );

    await provider.start();
    final sample = await provider.velocityStream.first;

    expect(sample.health, ProviderHealth.unavailable);
    expect(sample.confidence, 0);
    expect(provider.health, ProviderHealth.unavailable);
  });

  test('can retry after location service becomes available', () async {
    final gateway = _FakeLocationGateway(serviceEnabled: false);
    final provider = GpsVelocityProvider(gateway: gateway);

    await provider.start();
    final unavailable = await provider.velocityStream.first;

    gateway.serviceEnabled = true;
    gateway.positions = Stream.value(_position(speed: 2));
    final sampleFuture = provider.velocityStream.firstWhere(
      (sample) => sample.health == ProviderHealth.healthy,
    );
    await provider.start();
    final sample = await sampleFuture;

    expect(unavailable.health, ProviderHealth.unavailable);
    expect(sample.kmh, 7.2);
    expect(provider.health, ProviderHealth.healthy);
  });

  test('can retry after the position stream reports an error', () async {
    final positions = StreamController<Position>();
    final gateway = _FakeLocationGateway(positions: positions.stream);
    final provider = GpsVelocityProvider(gateway: gateway);

    await provider.start();
    positions.addError(StateError('gps stream interrupted'));
    await pumpEventQueue();

    gateway.positions = Stream.value(_position(speed: 3));
    final sampleFuture = provider.velocityStream.firstWhere(
      (sample) => sample.health == ProviderHealth.healthy,
    );
    await provider.start();
    final sample = await sampleFuture;

    expect(provider.health, ProviderHealth.healthy);
    expect(sample.kmh, 10.8);

    await positions.close();
  });

  test('requests permission when denied and emits GPS speed', () async {
    final gateway = _FakeLocationGateway(
      checkedPermission: LocationPermission.denied,
      requestedPermission: LocationPermission.whileInUse,
      positions: Stream.value(_position(speed: 10)),
    );
    final provider = GpsVelocityProvider(gateway: gateway);

    final sampleFuture = provider.velocityStream.firstWhere(
      (sample) => sample.health == ProviderHealth.healthy,
    );
    await provider.start();
    final sample = await sampleFuture;

    expect(gateway.requestPermissionCount, 1);
    expect(sample.kmh, 36);
    expect(sample.source, VelocitySource.gps);
    expect(sample.confidence, greaterThan(0.8));
    expect(provider.health, ProviderHealth.healthy);
  });

  test('marks weak GPS data as degraded', () async {
    final provider = GpsVelocityProvider(
      gateway: _FakeLocationGateway(
        positions: Stream.value(_position(speed: 8, accuracy: 80)),
      ),
    );

    final sampleFuture = provider.velocityStream.firstWhere(
      (sample) => sample.health == ProviderHealth.degraded,
    );
    await provider.start();
    final sample = await sampleFuture;

    expect(sample.kmh, 28.8);
    expect(sample.confidence, lessThan(1));
    expect(provider.health, ProviderHealth.degraded);
  });

  test('emits unavailable when permission is denied forever', () async {
    final provider = GpsVelocityProvider(
      gateway: _FakeLocationGateway(
        checkedPermission: LocationPermission.deniedForever,
      ),
    );

    await provider.start();
    final sample = await provider.velocityStream.first;

    expect(sample.health, ProviderHealth.unavailable);
  });
}

Position _position({
  required double speed,
  double accuracy = 5,
  double speedAccuracy = 0.5,
}) {
  return Position(
    longitude: 121.0,
    latitude: 31.0,
    timestamp: DateTime(2026),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: speedAccuracy,
  );
}

class _FakeLocationGateway implements LocationGateway {
  _FakeLocationGateway({
    this.serviceEnabled = true,
    this.checkedPermission = LocationPermission.whileInUse,
    this.requestedPermission = LocationPermission.whileInUse,
    Stream<Position>? positions,
  }) : positions = positions ?? const Stream.empty();

  bool serviceEnabled;
  final LocationPermission checkedPermission;
  final LocationPermission requestedPermission;
  Stream<Position> positions;
  int requestPermissionCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checkedPermission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCount += 1;
    return requestedPermission;
  }

  @override
  Stream<Position> getPositionStream({required LocationSettings settings}) {
    return positions;
  }
}
