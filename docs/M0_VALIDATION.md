# 小遇 M0 接入验证

日期：2026-11-09。Flutter 3.47.9 / Dart 3.13.7，Xcode 26.3，iPhone 17 Pro 真机。RTC 采用 Agora Flutter 6.6.4 / 原生 4.6.4，iOS 通过 SPM 集成。

## 已验证

- Android debug APK 构建成功；iOS 真机签名构建、安装与启动成功。
- iOS 构建产物及 APK 不含火山 RTC 依赖，iOS 工程无 Pods 集成。
- flutter analyze 通过，18 项单元/Widget 测试通过；真机热重载成功，运行时未发现异常。
- 用户在 App 内填写 Vidu API Key，只读鉴权通过。Key 与 RTC Token 未写入本文或构建配置。
- 官方形象目录匿名读取成功，用户已准备好一套 API 形象资产与角色配置。
- 实际创建参数 rtc.provider=agora；Vidu 字符串账号原样用于 Agora joinChannelWithUserAccount。
- 真实状态顺序：creating → initializing → joining → connected → ending → ended。
- 已收到入会、麦克风发布、远端音频订阅与视频渲染首帧回调；本地摄像头发布关闭。
- 用户确认画面、声音与说话后的语音回应都正常。
- 文字聊天与动作指令已发送；没有把发送成功标记为平台已读或动作已完成。
- 测试窗口设为 60 秒，自动挂断后 Vidu 查询确认 ended，返回 billed_seconds=53、credits_cost=80。二者为服务端返回值；不使用客户端计时器推算扣费。
- 通话历史已落盘，含 16 条发送/观测记录（用户侧 8、助手侧 8）。这些是协议观测记录，尚不认定为 16 句最终转写。
- 原生 RTC 引擎已释放。测试结束后没有再次创建收费会话。

## 真机发现与修复

permission_handler_apple 的 SPM manifest 未找到宿主 Info.plist，实际编译参数 PERMISSION_MICROPHONE=0。首轮测试在权限检查处失败，未创建收费 live。首次真实媒体测试临时使用 AVFoundation MethodChannel，通过上述通话验收。

2026-11-09 删除自定义权限桥接，双端统一使用 permission_handler。当时临时将 Apple 插件官方 9.6.5 源码作为本地依赖，使 SPM 沿源码路径定位宿主 Info.plist；该本地副本已于 2026-11-10 移除。此前实际 iOS 编译参数为 PERMISSION_MICROPHONE=1、PERMISSION_CAMERA=0、PERMISSION_PHOTOS=1。签名 iOS 构建、Android APK、静态检查与 18 项测试均通过。此次修改未额外创建收费会话。

2026-11-09 的权限插件方案已在 iPhone 上启动并成功热重载；通过业务实际使用的 MicrophonePermission.request() 调用 permission_handler，返回 true，Permission.microphone.status 为 granted，运行时无异常。设备此前已授权，本次未重置系统权限，首次授权弹窗与拒绝分支仍需专项验收。此前的 53 秒收费通话属于临时桥接方案的验证，不作为新权限方案重新通话的证据。

2026-11-10 按官方 SPM 文档恢复 pub 托管的 permission_handler_apple 9.6.5，删除 third_party 与 dependency_overrides。从项目根目录运行官方 manifest 检查，确认找到 Runner/Info.plist；iOS 签名构建成功，实际编译使用 pub 缓存源码，定义仍为 MICROPHONE=1、CAMERA=0、PHOTOS=1。静态分析与 18 项测试通过。SPM 远端仓库更新曾因网络失败，使用锁文件及已有仓库缓存解析后重新执行 Flutter 构建成功，未修改依赖版本或系统全局环境变量。

恢复 pub 版本后已安装启动新版，但 VM Service 连接超时，未获得本轮真机权限返回值或成功热重载结果；不能用前一天本地副本的设备结果代替此次运行验证。本次未重置权限、未创建收费通话，待连接恢复后补验。

Android Agora 插件默认 compileSdk=31，低于 Flutter 传递的 AndroidX 要求。根工程显式配置 compileSdkVersion=36，App 与插件共用后构建成功。

## 尚待验收

- Android 真机听说与音视频；当前仅有 APK 构建验证。
- 准备期挂断、断网/网络切换、强杀/锁屏回收、蓝牙/系统音频中断与多轮长时间稳定性。
- 当前连接超过 15 秒且未因活性中断；协议 Ping 对所有空闲场景的效果仍需扩大样本验证。
- 转写分片、修订、最终事件语义，以及动作效果、打断与切音色的独立效果确认。
- iOS 模拟器构建曾因 SQLite 原生库 GitHub 下载中断而失败，尚未完成模拟器启动验证；不影响本次真机验收结论。
- 知识库管理、长期记忆查看/清理、动作收藏、备份恢复与完整 PRD 功能仍需实现。
