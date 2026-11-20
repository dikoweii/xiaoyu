# 小遇工程约束

用户指令优先。保留用户明确授权的私有仓库配置，不打印凭证，不将运行时凭证放入镜像或构建输入。

每次任务先运行 `dart run tool/harness.dart skills --catalog`，查看 `.agents/skills/*/SKILL.md` 的实际目录。
通过 `report` 查询已有任务；不要覆盖未完成任务。无活动任务时运行
`dart run tool/harness.dart start --kind ui|logic|dependency|native|docs --goal "目标" --accept "可观测验收条件"`。
随后执行 `dart run tool/harness.dart skills --load`，阅读并应用输出的各个已安装 Skill 原文及其相关引用。
若输出被截断，继续读取对应原文件或 `build/harness/loaded-skills.md`，不能只看名称。
`xiaoyu-harness` 只协调项目流程，不能代替响应式布局、架构、诊断、测试等其他 Skill。
只有目标已完成才 `finish`。

## 实现边界

- PRD 决定行为；design.html 决定六屏外观，DESIGN.md 正文补充组件说明。
- 使用 Riverpod、Drift + SQLite、Agora 和 iOS SPM。通用 Skill 中的 ChangeNotifier/Provider 示例不能覆盖项目决策。
- 先检查官方文档与包实现，再添加依赖、原生桥接或依赖覆盖。相关决定写入 docs/DECISIONS.md，包含来源、必要性和替代方案。禁止恢复本地 permission_handler 副本、Pods 或火山 RTC。
- domain 只依赖 Dart 与领域工具；application 依赖领域端口；data 不依赖 UI。页面通过 Riverpod 控制器/视图状态发起业务命令，不直接 SQL、HTTP 或操作 RTC SDK。原生视频适配仅位于 ui/integrations。
- 不因测试失败删除测试、跳过测试、降低门槛、禁用字体缩放或锁定方向。不要手改生成文件；黄金图必须通过专门命令更新并附对照。
- 一台设备一个活动通话；不自动重试收费创建，取消后处理晚到响应；本地释放不代表平台结束或停止计费；模拟媒体不能充当真实 RTC 验收。

## 局部刷新与资源生命周期

- 计时、进度、音量、呼吸动画等高频变化应由独立组件或最小范围的监听器更新；仅拆出方法不构成刷新隔离。不要为局部展示每秒刷新整个页面或广播全局业务状态。Riverpod 在实际消费处监听必要字段，必要时使用 `select`；业务时间读取真实时钟，不按 Timer 回调次数累加。
- `build`、列表/动画 builder 及其调用的辅助方法保持无资源创建副作用：不得反复创建会注册监听、开启计时或持有外部句柄的动画、控制器、订阅、播放器和 RTC 会话。普通不可变 Widget、Tween、样式对象不属于此限制。
- 每个资源明确创建者、复用范围和释放者。同一生命周期内能安全复用就复用；在 State、Riverpod 控制器/服务的初始化阶段创建，在 `dispose` / `ref.onDispose` 或明确的结束流程中对应 `dispose`、`cancel`、`removeListener`、`close`。借用的共享资源由所有者释放，不能跨账号或通话盲目复用。
- 参数或来源变化时解绑旧监听再绑定新对象，避免重复注册；取消、失败、后台、重复进入及晚到响应都要考虑清理。`CurvedAnimation` 无独立反向曲线时优先复用 `CurveTween` 驱动链；需要时缓存 `CurvedAnimation` 并显式释放，不能指望 Transition 自动释放。
- 涉及高频刷新或资源生命周期的修复，应按风险用行为测试或运行观测验证：局部变化不重建无关区域、重复操作不增加活动资源/监听、停止及卸载后不再回调。截图和功能可用不能单独证明这些性质；具体审查步骤见 `docs/HARNESS.md`。

## 工具与验证

- `harness.yaml` 按任务种类及实际改动路径选择已安装 Skill。UI 使用 flutter-build-responsive-layout；架构使用 flutter-apply-architecture-best-practices；CLI 使用 dart-build-cli-app；测试使用 dart-add-unit-test；分析使用 dart-run-static-analysis。实现过程中改动范围扩大后，重新执行 `skills --load`。
- 任务语义需要额外能力时主动补充：运行异常 `skills --load --topic runtime`，依赖冲突 `--topic dependency_conflict`，覆盖率调查 `--topic coverage`；其他已安装技能通过 `--skill 名称` 选择。查看 harness.yaml 的完整主题映射；不要为凑数量加载无关 Skill。新安装技能自动进入目录，默认路由的调整须记录依据。
- `check` 检查本任务所需原文件的路径与内容摘要；缺失加载、Skill 改动或借用其他任务记录均失败。加载记录只证明 CLI 读取并输出文件，不能证明模型遵循了技能；不得把它当成可信 MCP 调用或技能应用证据。
- 依赖调查用 Dart MCP read_package_uris / rip_grep_packages，结合官方文档；Flutter 改动后尝试 MCP 热重载和运行时错误检查，UI 改动检查实际页面。
- MCP 不可用时记录失败和 CLI 替代检查；不得将自述填成可信调用记录或设备通过。
- 自动测试必须离线、临时数据、假凭证；不得读取设备真实 Key、创建收费 live 或将秘密打印到日志。真机收费验证仍需用户触发/授权。
- 运行 `check`、必要平台 `build` 和设备测试；最终运行 `finish`。报告明确区分代码、构建、设备、视觉和工具证据状态。
- 只能把实际执行通过的结果称为通过。超时、环境缺失、设备不可达标记阻塞/未验证。仓库内报告不是防篡改审计系统，不能证明 AI 永不作弊。

## 当前 UI 组件决策（2026-11-11）

按用户最新指令，使用官方 `liquid_glass_easy` 公开 API，允许大胆整理旧封装。
仅固定导航、玻璃按钮、开关和短确认弹窗使用玻璃；表单、卡片、列表、大面板及缺少的控件使用 Flutter 自带组件。
此要求取代此前“所有可见组件均使用 liquid_glass_widgets”的约束。禁止旧库及 easy 的 src 私有导入、自写折射器；不保留旧 Quality/全局主题兼容层。
