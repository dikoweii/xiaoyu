# 小遇本地 Harness

在仓库根目录执行 `dart run tool/harness.dart <命令>`。只验证 Android/iOS 手机，使用当前 Flutter/Dart SDK 和官方 pub/SPM 依赖，无云端 CI、全局配置或 AI 执行器。规则在 harness.yaml，项目工作流在 AGENTS.md 与 .agents/skills/xiaoyu-harness/SKILL.md。

```sh
dart run tool/harness.dart doctor
dart run tool/harness.dart skills --catalog
dart run tool/harness.dart start --kind ui --goal "修改目标" --accept "可观测验收条件" --risk "风险与验证边界"
dart run tool/harness.dart skills --load
dart run tool/harness.dart check
dart run tool/harness.dart build --platform both
dart run tool/harness.dart device --device-id DEVICE_ID
dart run tool/harness.dart self-test
dart run tool/harness.dart report
dart run tool/harness.dart finish
```

start 不覆盖未完成任务。首次无 Git 提交也能工作：使用 git ls-files 的已跟踪与未跟踪非忽略文件；后续按任务快照比较新增、删除、修改。生成物、日志、覆盖率在忽略的 build/harness 与 coverage。运行前后文件摘要变化则运行失效。后续文件变化、日志缺失或被改写也使旧报告失效。报告采用当前源码下最近一次相关运行，不用较早成功覆盖最新失败。

## 构建产物保留与执行前清理

`check/build/device/doctor/self-test/golden-update` 在创建本轮运行目录之前自动执行 GC，完成报告落盘后再执行一次，使新产物加入后也保持保留上限。`skills/report/finish/start` 不触发清理。`harness.yaml` 的 `retention.automatic` 控制自动清理，`artifacts_per_platform` 默认 3、至少 1；`runs_per_command` 默认 3，按命令/平台保留近期运行诊断。自动清理失败则停止本次命令，不静默忽略引用或 pin 文件错误。

```sh
dart run tool/harness.dart gc --dry-run
dart run tool/harness.dart gc --apply
dart run tool/harness.dart gc --pin RUN_ID --reason "发布版本或仍需保留的验收产物"
dart run tool/harness.dart gc --unpin RUN_ID
```

`gc` 默认只预览，不建立运行目录；输出安装包候选 `candidates`、整目录候选 `historyCandidates`、各自逻辑字节数、保留原因、引用检查结果及 pin 清单。每平台保留最近 3 份安装包，按命令/平台保留最近 3 个运行的日志、报告和截图；保留日志本身不会固定旧安装包。过期且未被保护的数字 ID 运行目录整体回收。运行中任务、未知/无效报告、手动 pin 及有效外部引用保护整个运行，因此这些明确依赖可能使份数超过配置值。

引用检查覆盖 Git 已跟踪及未忽略文本文件、`build/harness` 下非 runs/gc 目录的文本报告/交接文档，以及保留报告的跨运行引用；识别 `runs/<ID>`（含反斜线形式）。依赖按传递关系保护；已淘汰报告的引用不再保护旧构建。自动生成的 summary.json/md 只汇总历史，不构成固定请求，不参与引用保护。运行报告对自身产物的引用允许随其证据一起过期。仓库外的发布记录、仅写运行 ID 而不含路径的引用不会自动发现，需要显式 pin。`pins.json` 在本机保存；发布流程应在 GC 前固定需要长期保留的运行。

执行时加进程锁，先将对应报告写入 `evidenceState: expired` 再删除文件；整目录回收前复核报告摘要。保留下来的报告若丢弃了安装包，则保留历史执行结果和回收明细，但 `report/finish` 不再把过期证据判为有效。对仍有报告保留的源码版本，额外保留相应命令/平台最近一次结果，避免删除较晚失败后回退成较早的成功。源码、黄金图基线、当前任务/Skill 状态和 Flutter 缓存不在自动清理范围内。最近一次执行收据保存为 `build/harness/gc-last.json`，会被后续执行替换；文件回收与整目录回收字节分别记录，不能重复相加候选内的文件。长期保留的 GC 清单可放在 `build/harness/gc/`，该目录不参与引用保护。

字节统计为文件逻辑大小；APFS 克隆、压缩、快照会使实际磁盘释放量不同，需结合清理前后 `du` 判断。本次采用按数量保留，成功和失败日志都受历史运行保留上限约束，尚未实现内容哈希 blob 去重。旧研究探针、手动截图和交接材料等非 runs 临时文件，本轮按用途清理；今后仍应及时删除过期的临时记录，避免它们继续固定旧证据。

check 执行 Skill 加载门禁、SDK 版本、Dart AST 分层与依赖策略、格式、严格分析、中英文 ARB、权限说明、临时目录离线重新生成 l10n/Drift、全部宿主测试和有效行覆盖率。生成文件不手改；check 不自动更新黄金图或门槛。测试采用假凭证、临时 SQLite、Dio 内存适配和 IO 网络拒绝，不调用真实 Vidu；设备入口也替换收费 API、信令与媒体。校验错误不输出请求体、真实 token 或密钥。测试源中的 key/token 都是显式假值。

## 已安装 Skill 的发现与加载

`skills --catalog` 动态扫描 `.agents/skills/*/SKILL.md` 的 name、description 和正文摘要，新安装技能无需修改 Dart 代码即可列出。`skills` 输出计划，按 harness.yaml 中任务 kind、实际改动路径与显式 topic/skill 合并选择，并列出来源路径和选择原因。默认路径路由包括 UI、domain/application、CLI、测试和本地化；不靠关键词猜测所有任务语义。

```sh
dart run tool/harness.dart skills --kind ui
dart run tool/harness.dart skills --load --topic runtime
dart run tool/harness.dart skills --load --topic coverage
dart run tool/harness.dart skills --load --skill dart-use-path-package
```

`--load` 必须有活动任务，实际读取并向当前代理输出所选原始 SKILL.md 全文；代理需应用原文及必要引用，输出截断则继续读原文件。显式 topic/skill 保存到任务，后续 check 仍要求它们；其他技能按任务种类和变动范围自动路由。加载 xiaoyu-harness 不能替代其他必需技能。未知主题、技能未安装、无效元数据会报错，不能默默回退。

产物 `build/harness/skill-plan.json` 保存动态目录和计划，`loaded-skills.md` 保存本次输出的原文副本，`skill-loads.json` 记录任务 ID、原路径、SHA-256 和时间。check 核对当前任务应加载的每个文件；未加载、换任务或原文发生变化均失败。普通 check/doctor 不会自动补填加载记录。范围扩大后重新运行 skills --load。

Skill 是给代理的工作指令，CLI 无法替代理理解或执行它。记录只作为本地文件读取证据，skillLoading 与 skillApplication 分开报告，后者保留 unverified；不能伪装成宿主可信调用或已遵循证明。本次不引入 AI 执行器。默认路由需要评审维护，其他已安装 Skill 可按实际语义追加，不能用加载数量代替有效使用。

关键业务有效行合计至少 80%，每个文件至少 60%；范围包括 domain/application/data。生成文件、AST 确认的 Drift Table 声明式 schema 行和纯原生权限桥接不计分，原因见 DECISIONS.md。缺少文件覆盖率不能被解释为没有可执行代码。覆盖率只补充行为测试，不能代替取消、未知结果、释放、权限、持久化等场景。

## 局部刷新与资源生命周期审查

修改高频 UI 或资源生命周期前，先记录“哪个值变化、谁消费、哪些区域需要刷新”，以及“谁创建资源、复用到何时、何时解绑或释放”。规则入口在 AGENTS.md，xiaoyu-harness Skill 要求执行本节审查。

1. **确定更新边界。** 计时文字、上传进度、音量、呼吸动画应在独立组件或最小监听子树内更新。仅把页面代码拆成 build helper 不隔离刷新。局部展示状态不广播到整个页面；Riverpod 在实际消费位置监听必要字段，必要时使用 `select`。业务状态变化仍正常更新相关区域，不以禁止所有页面重建替代合理的更新边界。
2. **检查创建路径。** 审查 `build`、`itemBuilder`、动画/过渡 builder 及其辅助方法，排除反复创建 Timer、带监听的 Animation、Controller、StreamSubscription、播放器、连接等。普通 Widget、Tween 和样式对象可正常创建。不要为了复用而缓存会过期的 BuildContext 或用户配置。
3. **核对所有权和清理。** 在 State、Riverpod 控制器或服务的明确初始化阶段创建有状态资源，在相应生命周期结束时释放。同一所有者、相同身份/配置内安全复用；监听源变化时解绑旧对象再绑定新对象。只释放自己拥有的对象；取消、失败、离开页面、后台及晚到异步结果都要检查，避免重复注册、遗留回调或跨会话误用。
4. **按风险验证行为。** 高频更新用重建计数/稳定子树或性能观测验证无关视频、背景、按钮没有随之重建；资源用重复状态切换、进入退出、取消和失败场景验证活动数量不增长、卸载后无回调、清理次数正确。使用离线假对象、可控时钟和临时数据。资源问题不能仅凭截图、一次成功调用或静态分析判定解决；低风险文案/样式改动不要求新增此类测试。

通话绿点的具体约定：无独立 `reverseCurve` 时复用 `controller.drive(CurveTween(...)).drive(Tween(...))`；需要方向曲线时缓存 `CurvedAnimation`，并由所有者调用其 `dispose`。`FadeTransition` 更新动画时移除数值监听，不负责释放外部创建的 `CurvedAnimation` 状态监听。

现有 `test/ui/call_duration_test.dart` 验证秒数变化的重建范围、结束停止和卸载清理；`test/ui/call_composer_test.dart` 验证连续通话状态变化复用动画及减少动态效果。这两组测试列入 `required_tests`，`check` 会检查存在并实际执行。其他页面新增的资源或刷新路径仍需按本节审查；当前 AST 策略没有通用的刷新范围或资源所有权证明能力，不能把 Skill 加载记录当作这些行为已验证。

## 手机矩阵与截图

layout_matrix_test 从 harness.yaml 构造 4 尺寸 × 横竖屏 × Android/iOS × 中英文 × 1/2 倍字体 × 15 页面/面板，共 960 个基础组合，另有加载、空、错误、长内容与键盘用例。关键操作检查边界、48pt 目标和 hit testing，滚动后仍应触达。额外弹窗测试覆盖真实 modal，不用锁方向或禁缩放解决问题。

黄金图在 test/ui/goldens，含双平台六屏及小屏大字编辑/通话页。`dart run tool/harness.dart golden-update` 是唯一常规更新入口；更新后需要重跑 check。六屏固定素材和模拟视频，与真实用户数据分离。截图使用安装在 macOS 的 PingFang 系统字体与 Flutter MaterialIcons，时间、动画、数据库均固定；跨主机必须固定同版 Flutter 和系统字体后再比较。自动匹配只证明未回退。

build/harness/design-reference.png 是 design.html 的浏览器对照；design-comparison.png / design-comparison.html 放当前黄金图并标出差异。设计稿示例数据不导入产品。视觉审查状态默认 unverified，宿主用户确认后应保存该轮确认的宿主记录链接；CLI 不自动信任自行填写的“已确认”。本地仓库不能自动认证宿主记录或证明主观视觉符合度，finish 在 UI 任务缺乏确认时保守阻断。

## 构建、设备与完成状态

build 支持 android/ios/both，分别生成 debug APK 与无签名 iOS 真机包；校验官方原生栈与权限编译宏，保存产物摘要。无签名构建不是安装/运行验收。device 必须指定已连接手机，iOS 使用官方 integration_test driver 以支持无线调试，Android 使用 flutter test；均保留已安装应用的数据，不执行卸载。使用 integration_test/offline_smoke_test.dart：独立临时数据库、导航、权限状态读取、模拟通话前后台释放、数据库重开；不会索取/重置权限、读取真实 Key 或建立收费会话。模拟媒体通过不代表真实音视频或计费通过。

report / finish 分别列出 code、build.android/ios、device.android/ios、visualReview 与 mcpEvidence。passed/failed/blocked/unverified/not_applicable 各有独立含义。工具缺失、超时、网络错误不能变成 passed。finish 要求代码、受影响双端构建、设备和 UI 审查证据；自由文本验收条件仍须人工对照，程序不理解自然语言目标是否真正完成。未验证时返回非零，不把代码检查成功包装成整体完成。

MCP 热重载、运行错误与页面检查优先使用宿主真实记录。仓库产物只记录 CLI 能验证的内容；自述调用不能冒充可信 MCP。若无运行中的应用，保留未验证并记录 CLI 替代。真实收费通话按现有用户触发规则，所有门禁和钩子默认不创建 live。

离线设备测试还使用 wakelock_plus 读取平台屏幕唤醒标志：连接及模拟通话时开启，挂断/后台后关闭。driver 必须收到 screenAwakeDuringCall 和 screenSleepRestored 两项结果，否则不能通过。这验证原生标志与生命周期接线；真实手机自然超过自动锁屏时长和真实 RTC 持续通话仍须独立验收。

## 本地钩子与自测

`dart run tool/harness.dart install-hooks` 显式安装 pre-commit（check）与 pre-push（finish）。保留已有钩子，遇冲突报错；不安装全局 hook。钩子验证工作区快照；提交前应保持索引与工作区一致，避免提交另一套未验证内容。本次仅提供安装命令，不自动安装。

self-test 在临时夹具验证非法分层、跳过测试、禁用缩放、缺失覆盖率、过期/缺失/篡改/空报告、设备缺失证据和真实布局溢出检测。任何本地脚本都可能被有写权限者改写，不能保证 AI 永不违反规则，也不是防篡改审计系统。依赖、门槛、豁免或基线变化需记录来源、理由与替代方案，不由普通检查自动接受。
