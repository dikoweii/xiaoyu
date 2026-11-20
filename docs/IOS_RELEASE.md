# iOS 未签名 IPA

[返回 README](../README.md) · [Android 发布](ANDROID_RELEASE.md)

## GitHub 自动构建

[ios-unsigned-release.yml](../.github/workflows/ios-unsigned-release.yml) 在推送 `main` 或手动触发时构建并发布未签名 IPA。macOS 15 使用 Flutter 3.50.0、Swift Package Manager 和完整 Agora 依赖构建真机 ARM64 Release 应用，不需要 Apple 证书、描述文件或 App Store Connect 密钥。

构建命令为 `flutter build ios --release --no-codesign`。Flutter 的 IPA 导出需要签名，关闭签名会跳过导出，因此使用 [package_unsigned_ipa.py](../tool/ci/package_unsigned_ipa.py) 将 `build/ios/iphoneos/Runner.app` 封装为 `Payload/Runner.app`。打包器拒绝模拟器、缺少可执行文件、主应用已包含签名或描述文件的产物，保留可执行权限及框架符号链接。CI 使用 `xcrun lipo build/ios/iphoneos/Runner.app/Runner -verify_arch arm64` 确认主可执行文件含 ARM64 架构；输入文件放在命令选项之前。

格式、静态分析、CI 辅助脚本测试、构建和封装检查成功后，在独立 Ubuntu 任务发布 GitHub 预发布版本。GitHub Actions 不运行 UI、布局或黄金图测试；完整 Harness/UI 验证保留在本地。工作流不读取设备配置或创建真实收费通话。

标签为 `ios-v<版本>-unsigned-build.<运行编号>`；附件名为 `xiaoyu-<标签>.ipa`，同时提供 `SHA256SUMS.txt`。构建号为 `1000 + GITHUB_RUN_NUMBER`。Actions 产物保留 14 天，GitHub Release 附件独立保留。同一运行重试复用标签，新提交取消同分支旧构建。

## 下载和安装

在 [GitHub Releases](https://github.com/hsuehly/xiaoyu/releases) 下载标题含 `iOS` 和 `unsigned` 的 IPA。此文件需要自行重新签名后安装，不是可直接安装的签名包，也不能直接提交到 TestFlight 或 App Store。

最低系统为 iOS 15。重签工具需要为主应用及嵌入框架使用有效签名，并匹配自己的 Bundle ID、描述文件和权限。安装期限及允许的设备取决于所用签名。重签后须验证安全存储、麦克风授权和实际音视频通话；自动构建通过不代表这些设备行为已验收。
