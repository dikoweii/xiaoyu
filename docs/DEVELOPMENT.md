# 小遇开发指南

[返回 README](../README.md) · [使用说明](USAGE.md)

## 从源码运行

### 开发环境

| 项目 | 当前配置 |
| --- | --- |
| Flutter / Dart | Harness 固定 Flutter `3.50.0`、Dart `3.14.0`；`pubspec.yaml` 的 Dart 范围为 `^3.13.7` |
| Android | Android 8.0 / API 26 起；需 Android SDK、JDK 17 兼容环境；构建工具版本由项目及 Flutter 配置决定 |
| iOS | iOS 15 起；需 macOS + Xcode，当前开发环境为 Xcode 26.3；原生依赖使用 Swift Package Manager |
| 依赖下载 | 需访问 pub.dev、GitHub 和原生依赖仓库；首次构建会下载 SDK 与原生二进制 |

```sh
git clone https://github.com/hsuehly/xiaoyu.git
cd xiaoyu
flutter doctor -v
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

将 `DEVICE_ID` 替换为设备列表中的 ID。仓库若为私有，需要先拥有 GitHub 访问权限。Android 首次使用时，根据 doctor 提示执行 `flutter doctor --android-licenses`。

### iOS 模拟器与真机

```sh
open -a Simulator
flutter devices
flutter run -d SIMULATOR_DEVICE_ID
```

模拟器适合页面与离线流程检查；真实 RTC、麦克风、输出路由和持续通话效果需要手机验收。iOS 真机运行需在 Xcode 中选择自己的开发团队、配置签名，并在设备启用开发者模式。

iOS 使用 SPM，**无需执行 `pod install`**。权限配置及 Xcode 构建说明见 [iOS 权限配置](IOS_PERMISSIONS.md)。

### 生成代码与构建

保留 `pubspec.lock`、SPM 的 `Package.resolved`、Drift 和本地化生成代码，便于复现。修改数据库声明或 ARB 后重新生成，不直接修改生成文件。

```sh
flutter gen-l10n
dart run build_runner build
flutter build apk --debug
flutter build ios --debug --no-codesign
```

Android 调试包位于 `build/app/outputs/flutter-apk/app-debug.apk`。iOS 无签名产物不能直接安装到真机。当前 Android release 配置仍使用 debug 签名，正式发布前必须配置正式签名；仓库不提供发布证书。

## 本地验证

```sh
dart run tool/harness.dart doctor
dart run tool/harness.dart check
dart run tool/harness.dart build --platform both
dart run tool/harness.dart report
```

AI 开发与任务验收流程见 [AGENTS.md](../AGENTS.md) 和 [Harness 使用说明](HARNESS.md)。`check` 需要先按说明建立任务、加载相应 Skills；报告区分代码、构建、设备与视觉状态。日志和报告位于被忽略的 `build/harness/`，关键逻辑覆盖率门槛为合计至少 80%、每文件至少 60%。

自动测试使用临时数据库、假凭证和模拟媒体，不创建收费会话。手机矩阵以 `harness.yaml` 为准：当前覆盖 320×568、360×800、402×874 竖屏、Android/iOS、中英文及 1/2 倍字号。平板、桌面和横屏不属于当前验收范围。

黄金图通过独立命令 `dart run tool/harness.dart golden-update` 更新后审核，普通检查不会自动接受截图。宿主截图受 Flutter 和 macOS 系统字体版本影响，不能证明设备上的动态玻璃效果。

Material/Cupertino 控件已迁移至 Flutter 官方独立包 `material_ui` 和 `cupertino_ui`；本地化委托通过 `l10n.yaml` 配置随标准命令生成。验收状态以本地 `report` 最新结果为准，不将历史构建或模拟媒体测试当成当前版本的完整验收。

## 项目结构与文档

```text
lib/app/             启动、路由、依赖装配与生命周期
lib/domain/          领域模型和服务端口
lib/application/     通话协调与状态流转
lib/data/            Vidu、Agora、权限、凭证与本地仓储
lib/presentation/    Riverpod 控制器和快捷动作目录
lib/ui/              页面、共享控件与 RTC 视频适配
lib/l10n/            中英文文案及生成代码
test/                单元、交互、布局和黄金图测试
integration_test/    离线设备流程测试
tool/                本地 Harness
```

## 许可证

Copyright (c) 2026 hsuehly.

除另有声明外，本项目原创代码采用 [GNU Affero General Public License v3.0](../LICENSE)（`AGPL-3.0-only`，仅第 3 版）授权。允许使用、修改和商用；分发本项目或其修改版本时，需按协议提供对应源码。修改后的版本通过网络与用户交互时，需按协议向这些用户提供获取对应源码的入口。

品牌标识、第三方形象及其他第三方素材不包含在上述代码授权中；第三方依赖和 SDK 遵循各自许可证及服务条款。
