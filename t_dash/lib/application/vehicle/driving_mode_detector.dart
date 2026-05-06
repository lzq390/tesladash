import '../../domain/domain.dart';

class DrivingModeDetector {
  DrivingModeDetector({
    this.enterSpeedKmh = 5,
    this.exitSpeedKmh = 1,
    this.enterDuration = const Duration(seconds: 3),
    this.exitDuration = const Duration(seconds: 5),
  });

  final double enterSpeedKmh;
  final double exitSpeedKmh;
  final Duration enterDuration;
  final Duration exitDuration;

  DrivingModeState _state = const DrivingModeState(
    active: false,
    enteredAt: null,
    reason: null,
  );
  DateTime? _aboveEnterSince;
  DateTime? _belowExitSince;

  DrivingModeState get state => _state;

  DrivingModeState update(VelocitySample sample) {
    if (sample.health == ProviderHealth.unavailable) {
      return _state;
    }

    final timestamp = sample.timestamp;
    if (sample.kmh > enterSpeedKmh) {
      _aboveEnterSince ??= timestamp;
      _belowExitSince = null;

      if (!_state.active &&
          timestamp.difference(_aboveEnterSince!) >= enterDuration) {
        _state = DrivingModeState(
          active: true,
          enteredAt: timestamp,
          reason: 'GPS 速度超过 ${enterSpeedKmh.round()} km/h',
        );
      }
      return _state;
    }

    if (sample.kmh < exitSpeedKmh) {
      _belowExitSince ??= timestamp;
      _aboveEnterSince = null;

      if (_state.active &&
          timestamp.difference(_belowExitSince!) >= exitDuration) {
        _state = const DrivingModeState(
          active: false,
          enteredAt: null,
          reason: null,
        );
        _belowExitSince = null;
      }
      return _state;
    }

    _aboveEnterSince = null;
    if (!_state.active) {
      _belowExitSince = null;
    }
    return _state;
  }

  void reset() {
    _state = const DrivingModeState(
      active: false,
      enteredAt: null,
      reason: null,
    );
    _aboveEnterSince = null;
    _belowExitSince = null;
  }
}
