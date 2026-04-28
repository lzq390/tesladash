import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardSnapshotProvider = Provider<DashboardSnapshot>((ref) {
  return const DashboardSnapshot(
    vehicleName: 'Model 3',
    connectionLabel: 'BLE 已连接',
    batteryPercent: 86,
    rangeKm: 412,
    speedKmh: 0,
    speedSourceLabel: 'GPS',
    drivingLabel: '停车',
    climateLabel: '待机 22°C',
    tirePressureLabel: '2.8 / 2.8',
    chargingLabel: '未连接',
  );
});

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.vehicleName,
    required this.connectionLabel,
    required this.batteryPercent,
    required this.rangeKm,
    required this.speedKmh,
    required this.speedSourceLabel,
    required this.drivingLabel,
    required this.climateLabel,
    required this.tirePressureLabel,
    required this.chargingLabel,
  });

  final String vehicleName;
  final String connectionLabel;
  final int batteryPercent;
  final int rangeKm;
  final int speedKmh;
  final String speedSourceLabel;
  final String drivingLabel;
  final String climateLabel;
  final String tirePressureLabel;
  final String chargingLabel;

  String get batteryLabel => '$batteryPercent%';
  double get batteryProgress => batteryPercent.clamp(0, 100) / 100;
}
