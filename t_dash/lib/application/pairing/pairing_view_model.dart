import '../../domain/domain.dart';

enum PairingPhase {
  idle,
  permissionRequired,
  scanning,
  devicesFound,
  connecting,
  waitingForVehicle,
  paired,
  failed,
}

class PairingViewModel {
  const PairingViewModel({
    required this.phase,
    required this.title,
    required this.detail,
    required this.primaryActionLabel,
    required this.primaryActionEnabled,
    required this.isBusy,
    required this.devices,
    required this.selectedDeviceId,
  });

  factory PairingViewModel.initial() {
    return const PairingViewModel(
      phase: PairingPhase.idle,
      title: '连接附近车辆',
      detail: '打开蓝牙并靠近车辆，开始扫描附近的 BLE 设备。',
      primaryActionLabel: '扫描车辆',
      primaryActionEnabled: true,
      isBusy: false,
      devices: [],
      selectedDeviceId: null,
    );
  }

  final PairingPhase phase;
  final String title;
  final String detail;
  final String primaryActionLabel;
  final bool primaryActionEnabled;
  final bool isBusy;
  final List<BleDevice> devices;
  final String? selectedDeviceId;

  PairingViewModel copyWith({
    PairingPhase? phase,
    String? title,
    String? detail,
    String? primaryActionLabel,
    bool? primaryActionEnabled,
    bool? isBusy,
    List<BleDevice>? devices,
    String? selectedDeviceId,
    bool clearSelectedDevice = false,
  }) {
    return PairingViewModel(
      phase: phase ?? this.phase,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      primaryActionLabel: primaryActionLabel ?? this.primaryActionLabel,
      primaryActionEnabled: primaryActionEnabled ?? this.primaryActionEnabled,
      isBusy: isBusy ?? this.isBusy,
      devices: devices ?? this.devices,
      selectedDeviceId: clearSelectedDevice
          ? null
          : selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}
