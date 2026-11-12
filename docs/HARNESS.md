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

## 手机矩阵与截图

layout_matrix_test 从 harness.yaml 构造 4 尺寸 × 横竖屏 × Android/iOS × 中英文 × 1/2 倍字体 × 15 页面/面板，共 960 个基础组合，另有加载、空、错误、长内容与键盘用例。关键操作检查边界、48pt 目标和 hit testing，滚动后仍应触达。额外弹窗测试覆盖真实 modal，不用锁方向或禁缩放解决问题。

黄金图在 test/ui/goldens，含双平台六屏及小屏大字编辑/通话页。`dart run tool/harness.dart golden-update` 是唯一常规更新入口；更新后需要重跑 check。六屏固定素材和模拟视频，与真实用户数据分离。截图使用安装在 macOS 的 PingFang 系统字体与 Flutter MaterialIcons，时间、动画、数据库均固定；跨主机必须固定同版 Flutter 和系统字体后再比较。自动匹配只证明未回退。

build/harness/design-reference.png 是 design.html 的浏览器对照；design-comparison.png / design-comparison.html 放当前黄金图并标出差异。设计稿示例数据不导入产品。视觉审查状态默认 unverified，宿主用户确认后应保存该轮确认的宿主记录链接；CLI 不自动信任自行填写的“已确认”。本地仓库不能自动认证宿主记录或证明主观视觉符合度，finish 在 UI 任务缺乏确认时保守阻断。

## 构建、设备与完成状态

build 支持 android/ios/both，分别生成 debug APK 与无签名 iOS 真机包；校验官方原生栈与权限编译宏，保存产物摘要。无签名构建不是安装/运行验收。device 必须指定已连接手机，iOS 使用官方 integration_test driver 以支持无线调试，Android 使用 flutter test；均保留已安装应用的数据，不执行卸载。使用 integration_test/offline_smoke_test.dart：独立临时数据库、导航、权限状态读取、模拟通话前后台释放、数据库重开；不会索取/重置权限、读取真实 Key 或建立收费会话。模拟媒体通过不代表真实音视频或计费通过。

report / finish 分别列出 code、build.android/ios、device.android/ios、visualReview 与 mcpEvidence。passed/failed/blocked/unverified/not_applicable 各有独立含义。工具缺失、超时、网络错误不能变成 passed。finish 要求代码、受影响双端构建、设备和 UI 审查证据；自由文本验收条件仍须人工对照，程序不理解自然语言目标是否真正完成。未验证时返回非零，不把代码检查成功包装成整体完成。

MCP 热重载、运行错误与页面检查优先使用宿主真实记录。仓库产物只记录 CLI 能验证的内容；自述调用不能冒充可信 MCP。若无运行中的应用，保留未验证并记录 CLI 替代。真实收费通话按现有用户触发规则，所有门禁和钩子默认不创建 live。

## 本地钩子与自测

`dart run tool/harness.dart install-hooks` 显式安装 pre-commit（check）与 pre-push（finish）。保留已有钩子，遇冲突报错；不安装全局 hook。钩子验证工作区快照；提交前应保持索引与工作区一致，避免提交另一套未验证内容。本次仅提供安装命令，不自动安装。

self-test 在临时夹具验证非法分层、跳过测试、禁用缩放、缺失覆盖率、过期/缺失/篡改/空报告、设备缺失证据和真实布局溢出检测。任何本地脚本都可能被有写权限者改写，不能保证 AI 永不违反规则，也不是防篡改审计系统。依赖、门槛、豁免或基线变化需记录来源、理由与替代方案，不由普通检查自动接受。
