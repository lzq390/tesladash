enum VehiclePairingStep {
  sendingAddKeyRequest,
  waitingForVehicleConfirmation,
  paired,
  failed,
}

class VehiclePairingUpdate {
  const VehiclePairingUpdate({
    required this.step,
    required this.title,
    required this.detail,
  });

  const VehiclePairingUpdate.sendingAddKeyRequest()
    : step = VehiclePairingStep.sendingAddKeyRequest,
      title = '正在发送配对请求',
      detail = '正在通过 BLE 向车辆发送本机公钥。';

  const VehiclePairingUpdate.waitingForVehicleConfirmation()
    : step = VehiclePairingStep.waitingForVehicleConfirmation,
      title = '等待车机确认',
      detail = '请在车机屏幕上确认添加钥匙，必要时将卡片放到中控台读卡区域。';

  const VehiclePairingUpdate.paired()
    : step = VehiclePairingStep.paired,
      title = '配对成功',
      detail = '本机公钥已被车辆接受，可以继续使用近场仪表盘功能。';

  const VehiclePairingUpdate.failed(String message)
    : step = VehiclePairingStep.failed,
      title = '配对失败',
      detail = message;

  final VehiclePairingStep step;
  final String title;
  final String detail;

  bool get isBusy =>
      step == VehiclePairingStep.sendingAddKeyRequest ||
      step == VehiclePairingStep.waitingForVehicleConfirmation;
}
