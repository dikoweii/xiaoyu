# 小遇局部玻璃 UI

当前使用官方 `liquid_glass_easy: 5.2.0`，按用户 2026-11-11 的最新要求取代全玻璃组件体系。
设计颜色、信息结构仍参考 design.html 和 DESIGN.md；组件实现允许 Flutter 原生控件。

- main.dart 使用 `LiquidGlassShaders.ensureLoaded()` 预热，不需要全局 wrap 或额外原生插件。
- 固定 Tab 使用 LiquidGlassTabBar；标题导航使用 LiquidGlassAppBar，返回动作调用 Navigator.maybePop，保留编辑页 PopScope。
- AppButton/AppIconButton 组合公开 LiquidGlassButton，显式计算尺寸及语义。实色提交使用 FilledButton，文本动作使用 TextButton。
- AppToggle 使用 LiquidGlassSwitch，并补充启用/选中语义及 48pt 点击区域。Tab 的光学层排除语义，单独提供两块完整的可访问目标。
- 短确认使用 showLiquidGlassDialog/LiquidGlassAlertDialog、scrollable:true、键盘避让，普通 TextButton 提供确认/取消。
- 大面板使用 showModalBottomSheet；角色和通话菜单用 PopupMenuButton。表单为 TextField，卡片为普通 Material，列表为 ListTile，加载为 CircularProgressIndicator，通知为 SnackBar。
- 删除旧库、旧主题、GlassRenderPolicy、旧材质分支。禁止私有 src 导入、插件副本或自写玻璃渲染器。
- Impeller 使用库的实时 backdrop 路径；Skia 明确使用 Lite，不建立整页持续截图。减少动态时取消按钮触摸变形、Tab 膨胀和折射指示器；高对比模式使用 Lite。
- iOS Agora 保留官方 FlutterTexture；Android 控制按钮在视频背景时用 Lite。真实动态视频采样不以模拟媒体截图验收。

范围为 Android/iOS 手机竖屏；320×568、360×800、402×874，中英文、1×/2×字号及键盘矩阵。首页和我的视口继续铺满屏幕，安全间距在列表 padding 中随内容滚动；没有恢复上下黑色遮挡。

通话生命周期保留：joining 阶段先挂载视频，首帧到达后撤销连接界面并保留同一视频 State；挂断/取消立即返回来源或首页，协调器继续处理平台清理与账单待核对。没有自动创建收费通话。

高级设置、草稿、真实音色选择、账号隔离和设备语言保持原流程。知识库、试听及缺少分类仍明确显示未开放。

验证命令：`dart run tool/harness.dart check`、`self-test`、`build --platform both`、`device --device-id <id>`。黄金图仅由 `golden-update` 更新；宿主固定 Skia Lite，不能代表设备折射效果。分层报告与对照图在 build/harness；人工视觉、真实媒体和缺少的设备验收保持未验证。
