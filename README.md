# T-Dash

T-Dash 是一个面向特斯拉车主的手机仪表盘 App 原型项目。当前阶段只聚焦 App 开发和本地原型验证，不处理上架、商业化和合规材料。

## 当前状态

当前仓库包含三部分：

- `app/`：无需构建工具的移动端 PWA 原型，用来快速验证仪表盘布局、模拟车辆状态和驾驶模式。
- `t_dash/`：Flutter 手机 App 主工程，当前主要开发目录。
- `docs/`：产品、技术、UI/UX、执行规划和数据模型文档。

已完成的主要能力：

- PWA 仪表盘原型，可用于快速查看布局和交互参考。
- Flutter App 工程骨架、路由、主题和 Dashboard 页面。
- Domain 模型、Provider 抽象、Mock 数据源和 Dashboard ViewModel。
- GPS 车速数据源，支持定位权限、弱信号降级和数据源标注。
- 基于 GPS 速度的驾驶模式检测，行驶中拦截控制命令。
- BLE 未接入前默认显示未连接车辆，不展示 Mock 的已连接车辆状态。
- 小屏、横屏和系统字体放大下的基础布局回归测试。

## 本地查看原型

直接用浏览器打开：

```bash
app/index.html
```

如果浏览器对本地文件限制较多，也可以在项目根目录启动一个静态服务。优先使用系统自带的 Python：

```bash
python3 -m http.server 8000 -d app
```

然后访问：

```text
http://localhost:8000
```

也可以使用 Node 临时拉取 `serve` 包：

```bash
npx serve app
```

`npx serve app` 需要可用的 Node/npm 和网络环境；如果 npm 缓存或网络受限，使用上面的 Python 命令更稳。

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
│   ├── 06-数据模型与接口草案.md
│   └── 07-手动验证清单.md
├── t_dash/
│   ├── android/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── tools/
│   └── check-m0.sh
├── AGENTS.md
└── README.md
```

## 开发方向

近期开发顺序：

1. 已完成 PWA 仪表盘原型和 Flutter Dashboard 迁移。
2. 已完成 Domain 模型、Provider 抽象、Mock 数据闭环。
3. 当前 M3 已接入 GPS 车速 Provider 和驾驶模式检测。
4. 下一阶段优先做 Tesla BLE 权限、扫描、配对 PoC。
5. 后续再做车辆状态读取、基础控制命令和真车内测。

## Flutter 工程

Flutter 工程位于：

```text
t_dash/
```

当前仓库可以使用系统全局 `flutter`，也可以使用项目本地 Flutter SDK。项目本地 SDK 的路径约定为 `.toolchains/flutter`，该目录不会提交到 Git。

如果本机没有 Flutter，可在项目根目录初始化本地 SDK：

```bash
mkdir -p .toolchains
git clone --depth 1 -b stable https://github.com/flutter/flutter.git .toolchains/flutter
```

如果系统没有 `unzip`，仓库提供了一个 Python 版兼容 wrapper：`tools/bin/unzip`。运行 Flutter 命令前可使用下面的环境变量：

```bash
export TMPDIR=/tmp
export TMP=/tmp
export TEMP=/tmp
export HOME="$PWD/.toolchains/home"
export XDG_CONFIG_HOME="$PWD/.toolchains/home/.config"
export PUB_CACHE="$PWD/.toolchains/pub-cache"
export PATH="$PWD/tools/bin:$PWD/.toolchains/flutter/bin:$PATH"
```

M0 检查：

```bash
tools/check-m0.sh
```

单独验证 Flutter 工程：

```bash
cd t_dash
flutter analyze
flutter test
```

说明：本仓库的本地工具链已覆盖 Flutter、JDK、Android SDK command-line tools 和 Chrome for Testing。Linux 桌面工具链是可选项，手机 App 开发和 APK 构建不依赖它。

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
