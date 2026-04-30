enum VehicleConnectionStatus {
  unpaired,
  scanning,
  connecting,
  connected,
  degraded,
  disconnected,
  outOfRange,
  credentialInvalid,
}

enum ProviderHealth { healthy, degraded, unavailable }

enum VelocitySource { gps, fusedGpsImu, canBus, mock }

enum ControlCommandType {
  lock,
  unlock,
  startClimate,
  stopClimate,
  setClimateTemperature,
  flashLights,
  honk,
  openFrunk,
  openTrunk,
  enableSentry,
  disableSentry,
}

enum CommandStatus {
  queued,
  sending,
  success,
  failed,
  blockedByDrivingMode,
  timeout,
}
