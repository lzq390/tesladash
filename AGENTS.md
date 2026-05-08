# T-Dash 仪表盘 App Agent 工作说明

本文档用于初始化本地开发上下文，给后续参与本项目的 AI agent 或开发协作者提供统一约束。当前项目重点是开发一个面向手机的 Tesla 近场仪表盘 App，优先验证 App 本体体验，不以上架、商业化或合规材料为当前目标。

## 使用范围

本文件放在仓库根目录，作为本项目的默认 agent 指导文件。后续 agent 进入仓库后，应先阅读本文件，再结合 `README.md`、`docs/05-App开发执行规划.md` 和 `docs/06-数据模型与接口草案.md` 开始工作。

规则优先级：

1. 用户当前消息优先。
2. 系统/开发者安全约束优先。
3. 本文件作为项目级工程约束。
4. 具体代码以当前仓库真实内容为准。

## 项目方向

T-Dash 是一个手机端第二仪表盘 App。v1 目标是通过手机传感器和 Tesla 近场连接能力，为车内场景提供清晰、低干扰、可快速识别的仪表盘体验。

当前优先级：

1. Flutter App 工程化与仪表盘体验。
2. 统一数据模型和 Provider 抽象。
3. GPS 车速、驾驶模式和真实手机验证。
4. Tesla BLE 配对协议、状态读取和真实车辆验证。

暂不优先处理：

- 应用商店上架材料。
- 商标、软著、备案、商业合规专项。
- 云账号系统、远程控车、远程查车。
- OBD/CAN 硬件适配器供应链。
- 行程历史、能耗报告、社交分享等非核心功能。

## 当前仓库结构

- `app/`：PWA 仪表盘原型，用于快速验证视觉和交互。
- `t_dash/`：Flutter App 主工程，后续主要开发目录。
- `docs/`：产品、架构、UI/UX、执行规划、数据模型文档。
- `tools/`：本地检查脚本和辅助工具。
- `README.md`：项目启动、验证和工具链说明。

## 开发路线

当前已完成 M0/M1/M2/M3/M4 基础：

- PWA 原型可运行。
- Flutter 工程已初始化。
- Flutter Dashboard 已完成组件拆分、主题、路由和状态层接入。
- Domain 模型、Provider 抽象、Mock 数据源和 Dashboard ViewModel 已落地。
- GPS Velocity Provider 和驾驶模式检测已落地。
- BLE 权限、扫描、基础连接框架和配对页状态机占位已落地。
- APK 默认车辆状态应保持诚实：车辆状态读取未接入前显示未连接/未配对，不展示 Mock 已连接车辆。
- README 已补充本地静态服务、Flutter SDK 初始化和 M0 检查方式。
- `tools/check-m0.sh` 可用于基础验收。

下一步优先进入 M5 配对协议 PoC：

1. 阅读 Tesla `vehicle-command` 官方源码和 protobuf 定义。
2. 确认 BLE 服务 UUID、写特征、通知特征和分片策略。
3. 实现 P-256 本地密钥生成。
4. 实现 Keychain / Keystore 安全存储。
5. 实现 AddKey 配对请求和车辆响应处理。
6. 用 Mock BLE 覆盖成功、失败、超时和重新配对状态。

建议目标结构：

```text
t_dash/lib/
  main.dart
  app/
    t_dash_app.dart
    theme/
    routing/
  domain/
    models/
    services/
  application/
    dashboard/
    vehicle/
  infrastructure/
    mock/
    gps/
    tesla_ble/
  presentation/
    dashboard/
    shared/
```

继续开发时优先保持小步迁移。不要一次性重写全部 UI；真实 GPS/BLE 能力必须通过 Domain 接口进入 Application 层，再由 ViewModel 供 UI 消费。

## 架构原则

- UI 不直接依赖 GPS、BLE、CAN 或 Mock 数据源。
- `domain/` 只放实体、枚举、接口和纯业务约束。
- `application/` 负责组合状态、ViewModel、驾驶模式规则和控制命令策略。
- `infrastructure/` 负责具体数据源，包括 Mock、GPS/IMU、Tesla BLE、存储。
- `presentation/` 只消费 ViewModel，不处理协议细节。
- 所有真实控制命令必须经过驾驶模式和连接状态校验。
- App 术语应避免暗示官方授权；项目可以描述为 Tesla 车辆相关工具，但不要写成官方 Tesla App。

## 仪表盘体验原则

- 车速是第一视觉中心，进入页面 1 秒内必须可识别。
- 驾驶中减少交互，隐藏或禁用非必要控制。
- 触摸目标不小于 48dp。
- 小屏、横屏、系统字体放大时不能溢出。
- 状态文案必须诚实标注来源，例如 GPS、Mock、BLE。
- 数据缺失时显示未知或占位，不展示过期数字。
- 低频状态提示可以用 Snackbar/Toast，高频仪表数据不要作为整页 live region。

## 数据与控制规则

核心模型参考 `docs/06-数据模型与接口草案.md`。

优先落地：

- `VehicleState`
- `BatteryState`
- `VelocitySample`
- `PairingInfo`
- `ProviderHealth`
- `VehicleConnectionStatus`
- `ControlCommandType`
- `CommandStatus`

控制命令规则：

- 行驶中默认阻止车控命令。
- 连接不可用时命令应失败并给出明确反馈。
- Mock 环境必须能模拟成功、失败、驾驶中拦截三类结果。
- 任何密钥、token、车辆凭证不得进入日志、截图或普通文档。
- 不要把车辆 VIN、密钥、位置、账号信息或私有源码发送到外部 AI/在线服务，除非用户明确授权。

## 本地验证

常用检查：

```bash
node --check app/main.js
./tools/check-m0.sh
```

Flutter 单项检查可在 `t_dash/` 下运行：

```bash
flutter analyze
flutter test
```

如果使用本仓库本地 Flutter SDK，先参考 `README.md` 配置 `.toolchains/flutter` 和相关环境变量。

在当前仓库中，优先使用：

```bash
./tools/check-m0.sh
```

它会处理本地 Flutter SDK、缓存目录和基础验收命令。

## Git 协作规则

- 默认在当前分支完成小步提交。
- 不回滚用户已有改动。
- 修改前先确认 `git status -sb`。
- 混合工作区中只 stage 本任务相关文件。
- 每个提交聚焦一个明确目标。
- push 前确保 `flutter analyze` 和相关测试通过，除非工具链缺失并已在结果中说明。
- 当前远端仓库是 `https://github.com/lzq390/tesladash.git`，默认分支为 `master`。

## Review 处理规则

用户消息里可能反复携带旧 review findings。处理时必须以当前文件内容为准：

- 如果问题已经修复，不要重复当成待修项。
- 如果 review line number 已漂移，重新定位真实代码。
- 修复后运行对应检查。
- 对新增 review，优先处理 P2 及以上问题。

目前已修复过的历史问题包括：

- PWA 电量/续航模拟与帧率绑定。
- PWA 整页 `aria-live` 高频播报。
- PWA 自定义按钮缺少 `:focus-visible`。
- PWA 静止状态持续 60fps 渲染。
- PWA 菜单按钮无反馈。
- README 静态服务命令依赖说明。
- README 本地 Flutter SDK 初始化说明。
- Flutter 车速圆小屏文字溢出风险。
- Flutter 状态卡长文案和字体放大溢出风险。
- GoRouter Provider 释放路由实例。
- 非 Mock 数据源加载前误回退展示 Mock 状态。
- 模拟行驶控制直接依赖 Mock Provider。
- BLE/Pairing Widget 测试误触真实 BLE 插件。
- Widget 测试直接等待 fake async 定时器导致超时。

## 下一位 agent 的建议起点

如果用户说“继续执行”或“开始下个任务”，优先执行：

**M5：Tesla 配对协议 PoC、安全存储和真车配对准备。**

建议验收：

- 私钥通过安全存储保存，不进入日志、普通数据库或截图。
- Mock 环境可跑通配对成功、配对失败、超时和重新配对。
- 真车环境可至少完成一次 BLE 配对尝试。
- 配对失败时 UI 有明确失败原因和重试入口。
- `flutter analyze` 通过。
- `flutter test` 覆盖密钥、配对状态机、BLE 网关和 Widget 行为。
