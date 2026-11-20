# Android 自动发布

[返回 README](../README.md) · [开发指南](DEVELOPMENT.md)

## 发布流程

工作流位于 [.github/workflows/android-release.yml](../.github/workflows/android-release.yml)。推送到 `main` 或在 Actions 页面手动运行都会触发：

1. Ubuntu 24.04 使用固定 Flutter 3.50.0 / Dart 3.14.0 检查格式、静态分析、签名准备及全部普通测试，生成覆盖率数据。APK 工作流不依赖 macOS 或苹方字体。
2. Ubuntu 24.04 / JDK 17 使用仓库 Secrets 恢复签名配置，构建仅包含 `arm64-v8a` 的 release APK，并验证 APK 签名。
3. 独立发布任务使用 `GITHUB_TOKEN` 创建草稿、上传 APK 和 SHA-256 摘要，再发布 GitHub 预发布版本。

Release 标签为 `android-v<pubspec版本>-build.<运行编号>`，固定对应本次源码提交。Flutter 基础版本码为 `1000 + GITHUB_RUN_NUMBER`，ARM64 分包另加 ABI 偏移 `2000`，最终为 `3000 + GITHUB_RUN_NUMBER`；同一次运行重试沿用标签并覆盖对应附件。新提交会取消同分支尚未完成的旧构建。

APK 工作流中的检查和构建成功后才对用户公开 Release。失败或取消的上传可能留下未公开草稿，不会把不完整版本作为可下载发布。检查日志和构建产物在 Actions 中保留 14 天，Release 附件独立保留。

## 独立 UI 验证

[ui-verification.yml](../.github/workflows/ui-verification.yml) 在推送 main、Pull Request 或手动触发时，使用 macOS 15 跑完整 Harness 检查，保留生成代码校验、80/60 覆盖率门槛及黄金图对比。它通过 CoreText 查找系统苹方字体，不安装字体；字体缺失或截图不匹配会使该工作流失败，但不阻塞 APK 打包发布。APK 发布成功不等于 UI 验证通过，两份状态应分别查看。

## 一次性签名配置

在仓库的 **Settings → Secrets and variables → Actions → Repository secrets** 配置：

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | 小遇 JKS 签名文件的单行 Base64 |
| `ANDROID_STORE_PASSWORD` | JKS 存储密码 |
| `ANDROID_KEY_ALIAS` | 小遇密钥别名 |
| `ANDROID_KEY_PASSWORD` | 对应私钥密码 |

缺失或格式错误会使构建失败，不发布使用临时调试签名的 APK。固定签名用于后续覆盖升级，请妥善备份并沿用同一套密钥。

本次生成的专用签名保存在开发机 `~/.android/xiaoyu-release.jks`，对应的私有配置记录位于 `~/.android/xiaoyu-release-signing.json`。两者不进入仓库。记录文件用于配置上述四个 Secrets，密码和密钥值不应打印到日志。

签名配置由 [prepare_android_signing.py](../tool/ci/prepare_android_signing.py) 写入临时目录和被忽略的 `android/key.properties`，仅签名 APK；不会作为应用素材打包。任务结束时清理这两个临时文件。Vidu API Key 仍由用户在 App 中填写，不注入 CI 或安装包。

## 本地构建

开发机通过被忽略的 `android/key.properties` 指向专用签名；无此文件时保留原有本地调试签名兼容行为。

```sh
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

产物位于 `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`，发布附件名带 `-arm64-v8a` 后缀。CI 检查 APK 原生库目录仅包含该架构；保留全部 Agora 扩展，不支持 ARM32 或 x86_64 设备。正式分发必须确认已使用固定签名；自动发布流程强制要求四个 Secrets，并执行签名校验。

## 用户下载

在 [GitHub Releases](https://github.com/hsuehly/xiaoyu/releases) 选择最近的 Android 预发布版本，下载 `.apk`。支持 `arm64-v8a` 的 Android 8.0 及以上设备可安装，需要允许对应下载来源安装应用。

此前使用调试签名的版本无法被新正式签名覆盖，需要先卸载；卸载会删除应用本地角色和历史。后续同一正式签名的版本可正常覆盖升级。

APK 构建、签名和离线检查不证明真实 RTC、云端计费或设备视觉效果已经验收。当前为内测分发；[iOS 未签名 IPA](IOS_RELEASE.md) 由独立工作流构建，下载后需要自行重签安装。
