# 小遇 Xiaoyu

Flutter 数字人陪伴 App，按 PRD 先验证真实接入流程。项目在根目录，参考项目仅作交互参考，不复制代码或素材。

当前已实现：首页 / 我的、Vidu 官方形象选择、自建图片与账号资产选择、角色编辑、运行时 API Key 配置、Vidu 会话与 WebSocket 控制、Agora 媒体适配、文字/动作/打断/切音色、通话历史与结束状态核对、中英文切换。

当前属于 M0 接入阶段。知识库管理、记忆查看/清理、动作收藏、备份恢复及完整 PRD 验收尚未完成。

## 运行

环境：Flutter 3.47.9 / Dart 3.13.7，Android API 26+，iOS 15+，iOS 构建使用 Xcode 26.3。

```sh
flutter pub get
flutter run
```

在 App 的“我的 → 账号设置”输入 Vidu API Key，再执行只读鉴权检查。Key 可选择保存在系统安全存储中；不进入编译参数、仓库配置或打包资源。只有用户点击“开始通话”并确认后才创建收费 live。

## RTC 与 SPM

按用户 2026-11-09 的决定使用 Agora：agora_rtc_engine 6.6.4，原生 SDK 4.6.4，iris_method_channel 2.2.7。iOS 使用 Flutter 自动生成的 Swift Package Manager 集成，不需要 pod install；远端原生依赖固定在 ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved。已移除火山依赖与 CocoaPods 配置。

Vidu 创建参数显式使用 rtc.provider=agora。Vidu 返回的 user_id 原样传入 joinChannelWithUserAccount，不转成数值 UID；远端视频渲染使用 SDK 回调提供的 UID。仅发布麦克风，不发布本地摄像头。iOS 与 Android 统一使用 pub 官方 permission_handler 申请麦克风权限，无自定义原生权限桥接、源码副本或 dependency_overrides。Apple 实现由该包自动引入，SPM 根据 Info.plist 的用途声明启用权限。从项目根目录执行 flutter run / flutter build ios；直接从 Xcode 构建的路径配置及缓存说明见 [iOS 权限配置](docs/IOS_PERMISSIONS.md)。

官方角色目录使用用户提供的 Vidu 官网 roles 接口，匿名读取已验证。该接口独立封装，不携带 Vidu API Key 或浏览器 Cookie。网站角色 ID 与 API avatar ID 分开保存，选中图片后创建账号自己的公开 API 形象资产。

## 验证状态（2026-11-09）

- flutter analyze --no-pub 通过。
- flutter test --no-pub：18 项通过，覆盖取消后的晚到创建响应、重复启动、准备期重试、真实媒体就绪条件、结束核对、释放顺序、Agora 字符串账号与关闭摄像头配置。
- iOS 真机签名编译、安装与启动通过，Agora 经 SPM 链接；热重载成功，未发现运行时错误；构建产物无旧火山框架。
- Android debug APK 构建通过：build/app/outputs/flutter-apk/app-debug.apk。
- iOS 模拟器额外构建遇到 SQLite 原生库的 GitHub 下载中断，未完成模拟器启动验证；真机构建与启动已通过。
- 已使用用户在 App 内配置的 Key 完成一次 60 秒测试窗口的真实通话：Agora 入会、麦克风上行、远端音频订阅、视频首帧全部就绪，文字/动作发送成功；用户确认画面、声音、语音回应正常。自动挂断后 Vidu 确认 ended，billed_seconds=53、credits_cost=80。该样本覆盖超过 15 秒的连接存活；转写完整性、强杀/断网回收、准备期挂断和多轮稳定性仍需继续验收。

```sh
flutter gen-l10n
dart run build_runner build
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
flutter build ios --debug --no-codesign --no-pub
```

详见 [PRD](docs/PRD.md)、[技术架构](docs/TECHNICAL_ARCHITECTURE.md) 与 [实施决策](docs/DECISIONS.md)。

## 本地工程门禁

统一入口：`dart run tool/harness.dart doctor`，再执行 `check` / `build --platform both` / `report`。
完整使用、设备入口、矩阵、黄金图和证据边界见 [Harness](docs/HARNESS.md)。AI 工作流见 [AGENTS.md](AGENTS.md)。
