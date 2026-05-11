import 'dart:async';

import '../../domain/domain.dart';
import 'pairing_key_repository.dart';
import 'pairing_view_model.dart';

class PairingController {
  PairingController({
    required BleGateway bleGateway,
    required PairingKeyRepository pairingKeyRepository,
    required VehiclePairingService vehiclePairingService,
    List<String> scanServiceUuids = const [],
    Duration scanDuration = const Duration(seconds: 8),
    Duration connectionTimeout = const Duration(seconds: 12),
  }) : _bleGateway = bleGateway,
       _pairingKeyRepository = pairingKeyRepository,
       _vehiclePairingService = vehiclePairingService,
       _scanServiceUuids = List.unmodifiable(scanServiceUuids),
       _scanDuration = scanDuration,
       _connectionTimeout = connectionTimeout;

  final BleGateway _bleGateway;
  final PairingKeyRepository _pairingKeyRepository;
  final VehiclePairingService _vehiclePairingService;
  final List<String> _scanServiceUuids;
  final Duration _scanDuration;
  final Duration _connectionTimeout;
  final _viewModels = StreamController<PairingViewModel>.broadcast();

  PairingViewModel _state = PairingViewModel.initial();
  StreamSubscription<BleDevice>? _scanSubscription;
  StreamSubscription<BleConnectionUpdate>? _connectionSubscription;
  StreamSubscription<VehiclePairingUpdate>? _pairingSubscription;
  int _scanOperation = 0;
  int _connectionOperation = 0;

  PairingViewModel get currentState => _state;

  Stream<PairingViewModel> get viewModels async* {
    yield _state;
    yield* _viewModels.stream;
  }

  Future<void> startScan() async {
    if (_state.isBusy) {
      return;
    }
    final scanOperation = ++_scanOperation;
    ++_connectionOperation;
    await _connectionSubscription?.cancel();
    await _pairingSubscription?.cancel();
    _connectionSubscription = null;
    _pairingSubscription = null;

    _emit(
      _state.copyWith(
        phase: PairingPhase.scanning,
        title: '正在准备配对',
        detail: '正在准备本机 P-256 配对密钥。',
        primaryActionLabel: '准备中',
        primaryActionEnabled: false,
        isBusy: true,
        devices: [],
        clearSelectedDevice: true,
      ),
    );
    if (await _preparePairingKey(scanOperation) == null) {
      return;
    }

    final permissionGranted = await _bleGateway.requestPermissions();
    if (!_isCurrentScan(scanOperation)) {
      return;
    }
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
    if (!_isCurrentScan(scanOperation)) {
      return;
    }
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
        .scanForDevices(
          serviceUuids: _scanServiceUuids,
          requireLocationServicesEnabled: false,
        )
        .listen(
          (device) {
            if (!_isCurrentScan(scanOperation)) {
              return;
            }
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
            if (!_isCurrentScan(scanOperation)) {
              return;
            }
            _emitFailure(error.toString());
          },
        );

    await Future<void>.delayed(_scanDuration);
    if (!_isCurrentScan(scanOperation)) {
      return;
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (!_isCurrentScan(scanOperation)) {
      return;
    }
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
        detail: '本机配对密钥已准备。选择一个附近设备建立 BLE 连接。',
        primaryActionLabel: '重新扫描',
        primaryActionEnabled: true,
        isBusy: false,
        devices: List.unmodifiable(foundDevices),
      ),
    );
  }

  Future<void> connect(BleDevice device) async {
    ++_scanOperation;
    final connectionOperation = ++_connectionOperation;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _connectionSubscription?.cancel();
    await _pairingSubscription?.cancel();
    _connectionSubscription = null;
    _pairingSubscription = null;
    _emit(
      _state.copyWith(
        phase: PairingPhase.connecting,
        title: '正在准备配对',
        detail: '正在确认本机 P-256 配对密钥。',
        primaryActionLabel: '准备中',
        primaryActionEnabled: false,
        isBusy: true,
        selectedDeviceId: device.id,
      ),
    );
    final keyMaterial = await _preparePairingKey(
      connectionOperation,
      forConnection: true,
    );
    if (keyMaterial == null) {
      return;
    }

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

    final connectionCompleter = Completer<bool>();
    final pairingCompleter = Completer<void>();
    var bleConnected = false;

    void completeConnection(bool connected) {
      if (!connectionCompleter.isCompleted) {
        connectionCompleter.complete(connected);
      }
    }

    void completePairing() {
      if (!pairingCompleter.isCompleted) {
        pairingCompleter.complete();
      }
    }

    void failCurrentConnection(String message) {
      if (!_isCurrentConnection(connectionOperation)) {
        return;
      }
      ++_connectionOperation;
      unawaited(_pairingSubscription?.cancel());
      _pairingSubscription = null;
      _emitFailure(message);
      completeConnection(false);
      completePairing();
    }

    void finishPairingTerminal() {
      if (!_isCurrentConnection(connectionOperation)) {
        return;
      }
      ++_connectionOperation;
      unawaited(_connectionSubscription?.cancel());
      unawaited(_pairingSubscription?.cancel());
      _connectionSubscription = null;
      _pairingSubscription = null;
      completeConnection(true);
      completePairing();
    }

    void startVehiclePairing() {
      unawaited(_pairingSubscription?.cancel());
      _pairingSubscription = _vehiclePairingService
          .requestPairing(deviceId: device.id, keyMaterial: keyMaterial)
          .listen(
            (update) {
              if (!_isCurrentConnection(connectionOperation)) {
                return;
              }
              _emit(_stateFromPairingUpdate(update, device.id));
              if (!update.isBusy) {
                finishPairingTerminal();
              }
            },
            onError: (_) {
              failCurrentConnection('配对请求执行失败，请重新扫描后再试。');
            },
            onDone: () {
              if (_isCurrentConnection(connectionOperation) &&
                  !pairingCompleter.isCompleted) {
                failCurrentConnection('配对请求未完成，请重新扫描后再试。');
              }
            },
          );
    }

    _connectionSubscription = _bleGateway
        .connectToDevice(device.id, timeout: _connectionTimeout)
        .listen(
          (update) {
            if (!_isCurrentConnection(connectionOperation)) {
              return;
            }
            if (update.status == BleConnectionStatus.connected) {
              if (bleConnected) {
                return;
              }
              bleConnected = true;
              completeConnection(true);
              startVehiclePairing();
              return;
            }

            if (update.status == BleConnectionStatus.disconnected ||
                update.status == BleConnectionStatus.disconnecting) {
              failCurrentConnection('BLE 连接已断开，请重新扫描后再试。');
              return;
            }

            if (update.status == BleConnectionStatus.failed) {
              failCurrentConnection(update.message ?? '连接失败，请靠近车辆后重试。');
            }
          },
          onError: (Object error) {
            failCurrentConnection(error.toString());
          },
          onDone: () {
            if (!_isCurrentConnection(connectionOperation)) {
              return;
            }
            if (!bleConnected && !connectionCompleter.isCompleted) {
              failCurrentConnection('BLE 连接已断开，请重新扫描后再试。');
            }
          },
        );

    final connected = await connectionCompleter.future.timeout(
      _connectionTimeout,
      onTimeout: () async {
        if (!_isCurrentConnection(connectionOperation)) {
          return false;
        }
        await _connectionSubscription?.cancel();
        _connectionSubscription = null;
        failCurrentConnection('连接超时，请靠近车辆后重试。');
        return false;
      },
    );
    if (!connected) {
      return;
    }

    await pairingCompleter.future;
  }

  Future<void> cancel() async {
    ++_scanOperation;
    ++_connectionOperation;
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _pairingSubscription?.cancel();
    _scanSubscription = null;
    _connectionSubscription = null;
    _pairingSubscription = null;
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

  Future<PairingKeyMaterial?> _preparePairingKey(
    int operation, {
    bool forConnection = false,
  }) async {
    try {
      final keyMaterial = await _pairingKeyRepository.loadOrCreate();
      return forConnection
          ? _isCurrentConnection(operation)
                ? keyMaterial
                : null
          : _isCurrentScan(operation)
          ? keyMaterial
          : null;
    } on Object {
      final isCurrent = forConnection
          ? _isCurrentConnection(operation)
          : _isCurrentScan(operation);
      if (isCurrent) {
        _emitFailure('本地配对密钥不可用，请重试。');
      }
      return null;
    }
  }

  PairingViewModel _stateFromPairingUpdate(
    VehiclePairingUpdate update,
    String deviceId,
  ) {
    final phase = switch (update.step) {
      VehiclePairingStep.sendingAddKeyRequest => PairingPhase.connecting,
      VehiclePairingStep.waitingForVehicleConfirmation =>
        PairingPhase.waitingForVehicle,
      VehiclePairingStep.paired => PairingPhase.paired,
      VehiclePairingStep.failed => PairingPhase.failed,
    };

    return _state.copyWith(
      phase: phase,
      title: update.title,
      detail: update.detail,
      primaryActionLabel: update.isBusy ? '配对中' : '重新扫描',
      primaryActionEnabled: !update.isBusy,
      isBusy: update.isBusy,
      selectedDeviceId: deviceId,
    );
  }

  bool _isCurrentScan(int operation) {
    return operation == _scanOperation && !_viewModels.isClosed;
  }

  bool _isCurrentConnection(int operation) {
    return operation == _connectionOperation && !_viewModels.isClosed;
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
