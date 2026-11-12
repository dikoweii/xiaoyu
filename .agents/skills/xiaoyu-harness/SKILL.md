---
name: xiaoyu-harness
description: Coordinate Xiaoyu tasks by routing to the user's installed Skills and enforcing local verification gates. Use for Xiaoyu code, dependency, native or UI work; load the selected specialist Skills as well.
---

# 小遇任务流程

读取根目录 AGENTS.md、harness.yaml、相关 PRD 段落和已有任务 `report`。
运行 `dart run tool/harness.dart skills --catalog` 查看用户实际安装的技能。
无活动任务时用 `start --kind … --goal … --accept …` 建立目标及验收条件，不覆盖现有任务。

运行 `dart run tool/harness.dart skills --load`，阅读所选其他 Skill 的完整原文，
按需打开其中引用的文件并应用指导。输出截断时直接读原路径或 loaded-skills.md。
本 Skill 只协调流程，不能代替其他 Skill，也不复制其内容。
路由按种类和变动路径选择：UI→flutter-build-responsive-layout，架构→
flutter-apply-architecture-best-practices，CLI→dart-build-cli-app，测试→
dart-add-unit-test，分析→dart-run-static-analysis，本地化→flutter-setup-localization。
运行异常追加 `skills --load --topic runtime`，依赖冲突追加 `--topic dependency_conflict`，
覆盖率调查追加 `--topic coverage`；其他已安装技能用 `--skill 名称`，主题详见 harness.yaml。
改动范围扩大后重新加载。技能缺失报明路径/名称，不以本 Skill 顶替。
用户指令和项目决策优先；保留 Riverpod，不能照搬通用 Skill 的状态管理示例。

依赖/原生变化先查询官方文档和包源码。使用可用的 Dart MCP，修改后尝试
热重载、检查运行错误及页面；工具不可用必须如实记录，不能伪造事件。

实现只覆盖当前目标。运行 `dart run tool/harness.dart check`，处理实际失败。
UI/原生/依赖变更补双端 build、device；设备不可达不妨碍代码验证，但设备门禁不能通过。
UI 黄金图更新独立运行 `golden-update`，检查设计对照；不要把刚生成的图当成已有人审查。

`report` 查看分层状态，`finish` 判断完成条件。若输出阻塞，在最终答复列出未验证项，
不能声称全端通过。skill-routing 门禁只核对当前任务加载的原文件摘要；CLI 读取输出
不是执行 AI 模型，也不证明已遵循。skillApplication 保留 unverified，不能用自述伪造
宿主记录。机器记录不证明自述工具调用或视觉确认真实。
详见 docs/HARNESS.md。
