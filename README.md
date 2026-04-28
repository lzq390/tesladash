# T-Dash

T-Dash 是一个面向特斯拉车主的手机仪表盘 App 原型项目。当前阶段只聚焦 App 开发和本地原型验证，不处理上架、商业化和合规材料。

## 当前状态

当前仓库包含两部分：

- `app/`：无需构建工具的移动端 PWA 原型，用来快速验证仪表盘布局、模拟车辆状态和驾驶模式。
- `docs/`：产品、技术、UI/UX、执行规划和数据模型文档。

已完成的原型能力：

- 手机仪表盘主界面。
- 模拟 GPS 车速、电量、续航、锁车、空调、胎压和充电状态。
- 模拟行驶模式。
- 行驶中隐藏控制按钮。
- 菜单按钮占位反馈。
- 按钮键盘焦点态。
- 静止状态下停止无意义的高频刷新。

## 本地查看原型

直接用浏览器打开：

```bash
app/index.html
```

如果浏览器对本地文件限制较多，也可以在项目根目录启动一个静态服务：

```bash
npx serve app
```

或使用任意本地 HTTP server 指向 `app/` 目录。

## 目录结构

```text
.
├── app/
│   ├── assets/
│   │   └── car-top.svg
│   ├── index.html
│   ├── main.js
│   ├── manifest.webmanifest
│   └── styles.css
├── docs/
│   ├── 01-PRD-产品需求文档.md
│   ├── 02-技术架构与选型.md
│   ├── 04-UI-UX设计原则.md
│   ├── 05-App开发执行规划.md
│   └── 06-数据模型与接口草案.md
└── README.md
```

## 开发方向

近期开发顺序：

1. 继续用 `app/` 验证仪表盘交互。
2. 固化数据模型和 Provider 接口。
3. 准备 Flutter 工程。
4. 迁移 Dashboard UI。
5. 接入 GPS/IMU。
6. 做 Tesla BLE 配对 PoC。

## 文档入口

- 产品范围：[docs/01-PRD-产品需求文档.md](docs/01-PRD-产品需求文档.md)
- 技术架构：[docs/02-技术架构与选型.md](docs/02-技术架构与选型.md)
- UI/UX：[docs/04-UI-UX设计原则.md](docs/04-UI-UX设计原则.md)
- 执行规划：[docs/05-App开发执行规划.md](docs/05-App开发执行规划.md)
- 数据模型：[docs/06-数据模型与接口草案.md](docs/06-数据模型与接口草案.md)

## GitHub 推送

本地已配置远程仓库：

```bash
origin https://github.com/lzq390/tesladash.git
```

如需推送，先确保本机 GitHub 凭据可用，然后执行：

```bash
git push -u origin master
```
