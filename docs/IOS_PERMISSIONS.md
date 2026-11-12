# iOS 权限配置

遵循 [permission_handler 官方文档](https://pub.dev/packages/permission_handler) 的「iOS - Swift Package Manager」章节。应用依赖 permission_handler 12.0.1，其官方 Apple 实现由 pub 自动解析；无本地插件副本或依赖覆盖。

## Flutter 命令构建

本项目只有一个环境。ios/Runner/Info.plist 已包含 NSMicrophoneUsageDescription 和 NSPhotoLibraryUsageDescription，未声明摄像头用途。官方 SPM manifest 自动读取这些键并启用相应权限。

从项目根目录运行即可：

```sh
flutter pub get
flutter run
# 或
flutter build ios --debug
```

Dart 调用为 `await Permission.microphone.request()`。如果系统此前已授权，调用会直接返回 granted。

## 直接从 Xcode.app 构建

官方文档说明，Xcode.app 评估 SPM manifest 时的工作目录可能为 `/`，无法自动定位 Flutter 工程。按官方方法，指定当前项目的 Info.plist，然后退出并重开 Xcode：

```sh
# 在项目根目录执行；仅在使用 Xcode.app 直接构建时需要。
launchctl setenv PERMISSION_HANDLER_INFO_PLIST "$PWD/ios/Runner/Info.plist"
```

这会设置当前用户会话的环境变量，本项目不会自动执行。切换项目时应重新设置对应路径；不再需要时执行 `launchctl unsetenv PERMISSION_HANDLER_INFO_PLIST`。

## 配置缓存与检查

官方文档指出，修改 Info.plist 或权限环境变量不会自动触发 SPM manifest 重新求值。配置变化后应清理相关项目的 DerivedData/包缓存再构建。官方示例清理整个 DerivedData；日常使用可仅清理小遇对应的项目缓存，保留其他工程。

需要独立检查配置时，从项目根目录执行以下命令，通过 Flutter 生成的依赖链接读取 pub 包：

```sh
PERMISSION_HANDLER_VERBOSE=1 swift package --manifest-cache none \
  --package-path ios/Flutter/ephemeral/Packages/.packages/permission_handler_apple-9.6.5 \
  dump-package > /tmp/xiaoyu-permissions.json
```

Flutter 生成的包路径可能因版本而异（例如没有版本后缀），以 `ios/Flutter/ephemeral/Packages/.packages/` 中的实际目录为准。预期定义为 PERMISSION_MICROPHONE=1、PERMISSION_CAMERA=0、PERMISSION_PHOTOS=1。最终仍需检查实际编译参数及真机返回值，不能仅凭 manifest 输出推定已完成设备验收。
