const initialVehicleState = {
  connection: "connected",
  driving: false,
  locked: true,
  climateOn: false,
  battery: 86,
  range: 412,
  speed: 0,
  targetSpeed: 0,
  tirePressure: {
    frontLeft: 2.8,
    frontRight: 2.8,
    rearLeft: 2.8,
    rearRight: 2.8,
  },
  chargeState: "disconnected",
  speedSource: "GPS",
};

function createVehicleStore(initialState) {
  let state = { ...initialState };
  const listeners = new Set();

  function getState() {
    return state;
  }

  function setState(updater) {
    const nextState = typeof updater === "function" ? updater(state) : updater;
    state = {
      ...state,
      ...nextState,
    };
    listeners.forEach((listener) => listener(state));
  }

  function subscribe(listener) {
    listeners.add(listener);
    listener(state);

    return () => {
      listeners.delete(listener);
    };
  }

  return {
    getState,
    setState,
    subscribe,
  };
}

function createMockVehicleProvider(store) {
  let lastFrameTime = performance.now();
  let animationFrameId = 0;

  function shouldAnimate(state) {
    return state.driving || state.speed > 0 || state.targetSpeed > 0;
  }

  function startTicker() {
    if (animationFrameId !== 0) {
      return;
    }

    lastFrameTime = performance.now();
    animationFrameId = window.requestAnimationFrame(tick);
  }

  function setDriving(nextDriving) {
    store.setState({
      driving: nextDriving,
      targetSpeed: nextDriving ? 58 : 0,
      connection: nextDriving ? "driving" : "connected",
      chargeState: nextDriving ? "driving" : "disconnected",
    });
    startTicker();
  }

  function executeCommand(action) {
    const state = store.getState();

    if (state.driving) {
      return {
        ok: false,
        message: "请停车后再操作",
      };
    }

    if (action === "lock") {
      store.setState({ locked: !state.locked });
      return {
        ok: true,
        message: state.locked ? "车辆已解锁" : "车辆已上锁",
      };
    }

    if (action === "climate") {
      store.setState({ climateOn: !state.climateOn });
      return {
        ok: true,
        message: state.climateOn ? "空调已关闭" : "空调已开启",
      };
    }

    if (action === "flash") {
      return {
        ok: true,
        message: "已发送闪灯指令",
      };
    }

    return {
      ok: false,
      message: "暂不支持该操作",
    };
  }

  function tick(now = performance.now()) {
    animationFrameId = 0;
    const deltaSeconds = Math.min((now - lastFrameTime) / 1000, 0.25);
    lastFrameTime = now;

    const state = store.getState();

    if (!shouldAnimate(state)) {
      return;
    }

    const targetSpeed = state.driving ? 58 + Math.sin(now / 1300) * 4 : 0;
    let speed = state.speed + (targetSpeed - state.speed) * 0.12;

    if (!state.driving && speed < 0.45) {
      speed = 0;
    }

    const tirePressure = state.driving
      ? { ...state.tirePressure, rearRight: 2.9 }
      : { ...state.tirePressure, rearRight: 2.8 };

    store.setState({
      speed,
      targetSpeed,
      battery: state.driving ? Math.max(0, state.battery - 0.02 * deltaSeconds) : state.battery,
      range: state.driving ? Math.max(0, state.range - 0.1 * deltaSeconds) : state.range,
      tirePressure,
    });

    if (shouldAnimate(store.getState())) {
      animationFrameId = window.requestAnimationFrame(tick);
    }
  }

  return {
    setDriving,
    executeCommand,
    tick,
  };
}

const elements = {
  shell: document.querySelector(".app-shell"),
  menuButton: document.querySelector("#menuButton"),
  speedValue: document.querySelector("#speedValue"),
  speedSource: document.querySelector("#speedSource"),
  driveModeLabel: document.querySelector("#driveModeLabel"),
  connectionText: document.querySelector("#connectionText"),
  batteryTop: document.querySelector("#batteryTop"),
  batteryPercent: document.querySelector("#batteryPercent"),
  batteryFill: document.querySelector("#batteryFill"),
  rangeValue: document.querySelector("#rangeValue"),
  lockState: document.querySelector("#lockState"),
  doorState: document.querySelector("#doorState"),
  climateStatus: document.querySelector("#climateStatus"),
  tireStatus: document.querySelector("#tireStatus"),
  chargeStatus: document.querySelector("#chargeStatus"),
  driveToggle: document.querySelector("#driveToggle"),
  driveToggleText: document.querySelector("#driveToggleText"),
  lockButtonText: document.querySelector("#lockButtonText"),
  climateButtonText: document.querySelector("#climateButtonText"),
  toast: document.querySelector("#toast"),
};

const store = createVehicleStore(initialVehicleState);
const vehicleProvider = createMockVehicleProvider(store);
let toastTimer = 0;

function showToast(message) {
  window.clearTimeout(toastTimer);
  elements.toast.textContent = message;
  elements.toast.classList.add("is-visible");
  toastTimer = window.setTimeout(() => {
    elements.toast.classList.remove("is-visible");
  }, 1800);
}

function toDashboardViewModel(state) {
  const batteryText = `${Math.round(state.battery)}%`;
  const tireText = `${state.tirePressure.frontLeft.toFixed(1)} / ${state.tirePressure.rearRight.toFixed(1)}`;

  return {
    batteryText,
    batteryWidth: `${state.battery}%`,
    chargeStatus: state.chargeState === "driving" ? "行驶中" : "未连接",
    climateButtonText: state.climateOn ? "关空调" : "开空调",
    climateStatus: state.climateOn ? "运行 22°C" : "待机 22°C",
    connectionText: state.driving ? "驾驶模式已启用" : "BLE 已连接",
    doorState: state.locked ? "门窗关闭" : "请确认门窗",
    driveModeLabel: state.driving ? "行驶" : "停车",
    driveToggleText: state.driving ? "结束模拟" : "模拟行驶",
    isDriving: state.driving,
    lockButtonText: state.locked ? "解锁" : "上锁",
    lockState: state.locked ? "已上锁" : "已解锁",
    range: Math.round(state.range),
    speed: Math.round(state.speed),
    speedSource: state.driving ? `${state.speedSource} 模拟` : state.speedSource,
    tireStatus: tireText,
  };
}

function render(state) {
  const viewModel = toDashboardViewModel(state);

  elements.shell.classList.toggle("is-driving", viewModel.isDriving);
  elements.speedValue.textContent = viewModel.speed;
  elements.speedSource.textContent = viewModel.speedSource;
  elements.driveModeLabel.textContent = viewModel.driveModeLabel;
  elements.connectionText.textContent = viewModel.connectionText;
  elements.connectionText.classList.toggle("is-driving", viewModel.isDriving);
  elements.batteryTop.textContent = viewModel.batteryText;
  elements.batteryPercent.textContent = viewModel.batteryText;
  elements.batteryFill.style.width = viewModel.batteryWidth;
  elements.rangeValue.textContent = viewModel.range;
  elements.lockState.textContent = viewModel.lockState;
  elements.doorState.textContent = viewModel.doorState;
  elements.climateStatus.textContent = viewModel.climateStatus;
  elements.tireStatus.textContent = viewModel.tireStatus;
  elements.chargeStatus.textContent = viewModel.chargeStatus;
  elements.driveToggleText.textContent = viewModel.driveToggleText;
  elements.lockButtonText.textContent = viewModel.lockButtonText;
  elements.climateButtonText.textContent = viewModel.climateButtonText;
}

document.querySelectorAll("[data-action]").forEach((button) => {
  button.addEventListener("click", () => {
    const result = vehicleProvider.executeCommand(button.dataset.action);
    showToast(result.message);
  });
});

elements.driveToggle.addEventListener("click", () => {
  const nextDriving = !store.getState().driving;
  vehicleProvider.setDriving(nextDriving);
  showToast(nextDriving ? "行驶中已隐藏控制按钮" : "已恢复停车控制");
});

elements.menuButton.addEventListener("click", () => {
  showToast("设置页开发中");
});

store.subscribe(render);
vehicleProvider.tick();
