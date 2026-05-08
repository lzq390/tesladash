import 'dart:async';

import '../../domain/domain.dart';
import 'pairing_view_model.dart';

class PairingController {
  PairingController({
    required BleGateway bleGateway,
    Duration scanDuration = const Duration(seconds: 8),
  }) : _bleGateway = bleGateway,
       _scanDuration = scanDuration;

  final BleGateway _bleGateway;
  final Duration _scanDuration;
  final _viewModels = StreamController<PairingViewModel>.broadcast();

  PairingViewModel _state = PairingViewModel.initial();
  StreamSubscription<BleDevice>? _scanSubscription;
  StreamSubscription<BleConnectionUpdate>? _connectionSubscription;

  PairingViewModel get currentState => _state;

  Stream<PairingViewModel> get viewModels async* {
    yield _state;
    yield* _viewModels.stream;
  }

  Future<void> startScan() async {
    if (_state.isBusy) {
      return;
    }
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    final permissionGranted = await _bleGateway.requestPermissions();
    if (!permissionGranted) {
      _emit(
        _state.copyWith(
          phase: PairingPhase.permissionRequired,
          title: '需要蓝牙权限',
          detail: '请允许蓝牙权限后再扫描附近车辆。',
          primaryActionLabel: '重新扫描',
          primaryActionEnabled: true,
          isBusy: false,
          devices: [],
          clearSelectedDevice: true,
        ),
      );
      return;
    }

    final status = await _bleGateway.currentStatus();
    if (status != BleAdapterStatus.ready) {
      _emitFailure(_adapterStatusMessage(status));
      return;
    }

    final foundDevices = <BleDevice>[];
    _emit(
      _state.copyWith(
        phase: PairingPhase.scanning,
        title: '正在扫描',
        detail: '保持手机靠近车辆，正在查找附近 BLE 设备。',
        primaryActionLabel: '扫描中',
        primaryActionEnabled: false,
        isBusy: true,
        devices: [],
        clearSelectedDevice: true,
      ),
    );

    await _scanSubscription?.cancel();
    _scanSubscription = _bleGateway
        .scanForDevices(requireLocationServicesEnabled: false)
        .listen(
          (device) {
            if (foundDevices.any((item) => item.id == device.id)) {
              return;
            }
            foundDevices.add(device);
            _emit(
              _state.copyWith(
                phase: PairingPhase.scanning,
                detail: '已发现 ${foundDevices.length} 个附近设备。',
                devices: List.unmodifiable(foundDevices),
              ),
            );
          },
          onError: (Object error) {
            _emitFailure(error.toString());
          },
        );

    await Future<void>.delayed(_scanDuration);
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (_state.phase == PairingPhase.failed ||
        _state.phase == PairingPhase.permissionRequired) {
      return;
    }

    if (foundDevices.isEmpty) {
      _emitFailure('未发现附近 BLE 设备，请确认蓝牙已开启并靠近车辆。');
      return;
    }

    _emit(
      _state.copyWith(
        phase: PairingPhase.devicesFound,
        title: '选择车辆',
        detail: '选择一个附近设备建立 BLE 连接。Tesla 配对协议将在下一阶段接入。',
        primaryActionLabel: '重新扫描',
        primaryActionEnabled: true,
        isBusy: false,
        devices: List.unmodifiable(foundDevices),
      ),
    );
  }

  Future<void> connect(BleDevice device) async {
    await _connectionSubscription?.cancel();
    _emit(
      _state.copyWith(
        phase: PairingPhase.connecting,
        title: '正在连接',
        detail: '正在连接 ${device.displayName}。',
        primaryActionLabel: '连接中',
        primaryActionEnabled: false,
        isBusy: true,
        selectedDeviceId: device.id,
      ),
    );

    final completer = Completer<void>();
    _connectionSubscription = _bleGateway
        .connectToDevice(device.id)
        .listen(
          (update) {
            if (update.status == BleConnectionStatus.connected) {
              _emit(
                _state.copyWith(
                  phase: PairingPhase.waitingForVehicle,
                  title: 'BLE 已连接',
                  detail: '基础连接已建立。车机确认和 Tesla 配对协议将在 M5 接入。',
                  primaryActionLabel: '重新扫描',
                  primaryActionEnabled: true,
                  isBusy: false,
                  selectedDeviceId: device.id,
                ),
              );
              if (!completer.isCompleted) {
                completer.complete();
              }
              return;
            }

            if (update.status == BleConnectionStatus.failed) {
              _emitFailure(update.message ?? '连接失败，请靠近车辆后重试。');
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          },
          onError: (Object error) {
            _emitFailure(error.toString());
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );

    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () async {
        await _connectionSubscription?.cancel();
        _connectionSubscription = null;
        _emitFailure('连接超时，请靠近车辆后重试。');
      },
    );
  }

  Future<void> cancel() async {
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _scanSubscription = null;
    _connectionSubscription = null;
    _emit(PairingViewModel.initial());
  }

  Future<void> dispose() async {
    await cancel();
    await _viewModels.close();
  }

  void _emit(PairingViewModel state) {
    _state = state;
    if (!_viewModels.isClosed) {
      _viewModels.add(state);
    }
  }

  void _emitFailure(String message) {
    _emit(
      _state.copyWith(
        phase: PairingPhase.failed,
        title: '配对暂不可用',
        detail: message,
        primaryActionLabel: '重新扫描',
        primaryActionEnabled: true,
        isBusy: false,
      ),
    );
  }
}

String _adapterStatusMessage(BleAdapterStatus status) {
  return switch (status) {
    BleAdapterStatus.ready => '蓝牙已就绪',
    BleAdapterStatus.unknown => '正在检查蓝牙状态',
    BleAdapterStatus.unsupported => '此设备不支持蓝牙低功耗',
    BleAdapterStatus.unauthorized => '蓝牙权限未授权',
    BleAdapterStatus.poweredOff => '请开启蓝牙',
    BleAdapterStatus.locationServicesDisabled => '请开启系统定位服务',
  };
}
