# 小遇局部玻璃 UI 迁移调研

调研日期：2026-11-11。目标库：官方 `liquid_glass_easy: 5.2.0`。迁移已按用户后续授权实施；原调研建议供来源追溯，当前实现以 docs/LIQUID_GLASS_UI.md 为准。

## 结论与使用范围

可迁移，符合“少量固定控件有玻璃，内容使用普通组件”的目标。当前旧库也允许局部使用；全玻璃源于此前项目约束，并非 Flutter 或旧库的必然要求。此次按用户的新要求以 easy 为目标，先取消全玻璃约束，再迁移，不保留两套玻璃系统长期并存。

5.2.0 已有按钮、开关、AppBar、TabBar、确认弹窗与底部面板，不必自己实现这些组件的折射渲染。它模拟 iOS 风格，不是 UIKit 原生 Liquid Glass 控件的封装，也不能直接继承旧库的导航、无障碍及自适应质量能力。

建议允许玻璃的范围：悬浮 Tab、顶部返回/操作按钮或 AppBar、开关、少量主要操作按钮、简短菜单与确认弹窗。普通角色卡、账号卡、历史记录、表单、分隔线、加载提示与音色列表恢复 Flutter 常规组件，保持现有深色和淡紫设计。

不要把每个滚动列表项、每个弹窗选项重新变成独立折射面板；菜单只要一个玻璃外壳，内部使用普通文字/按钮。通话字幕与输入区域先使用易读的普通半透明表面，真实视频上的折射单独验证。

## 核对的官方能力

- pub.dev 当前版本 5.2.0，发布于 2026-11-02；MIT；依赖仅 Flutter SDK 和 meta，无原生 plugin 声明，因此新库本身不需要 Pods、SPM 插件或自建 Swift 桥接。项目其他原生插件继续使用 SPM。
- 清单约束为 Dart >=3.6.2 <4.0.0、Flutter >=3.3.0。项目为 Flutter 3.47.9 / Dart 3.13.7，已用当前工具链在独立目录完成依赖解析和示例静态分析；不以宽松的 Flutter 最低版本声明代替实际验证。
- Impeller 使用实时 backdrop，不要求全局 `LiquidGlassView`。Skia 无 View 时为磨砂降级；要在 Skia 上折射实际页面内容，才需明确配置 View 的背景捕获。开关自身拥有背景，两条路径都可独立使用。
- `LiquidGlassStyle` 统一颜色、折射、模糊、形状；不能直接照搬旧库的 thickness/quality 等参数，需重新调校。
- `LiquidGlassEngine.liteGlassOnSkia`、`liteGlassOnImpeller` 和单样式 `liteGlass` 提供无折射降级。Lite 不是旧库的 Standard，也不自动替代减少动态、减少透明度和性能策略。
- 官方建议玻璃悬浮在内容上方，避免放在滚动列表内。Android 拉伸 overscroll 会隔离列表纹理，内部镜片可能短暂读到黑色；减少列表里的镜片是首选，不通过关闭正常滚动解决。
- `LiquidGlassBatch` 适合确认不重叠的镜片共享 backdrop；默认先用少数独立控件，测量后再决定是否批处理，不预先引入复杂 Blender/Morph 系统。

## 组件对应

| 当前项目 | 迁移建议 | 行为差异或保留要求 |
| --- | --- | --- |
| `XButton` / `XIcon`、`GlassButton` | 指定玻璃按钮用 `LiquidGlassButton`；普通动作用 Flutter 按钮 | easy 按钮默认高度 48，child 不决定宿主高度；大字号需按文本布局增高。保留最小 48pt、禁用状态和语义，不创建多个通用按钮工厂 |
| `XToggle` / `GlassSwitch` | `LiquidGlassSwitch` | onChanged 必填，不直接支持旧的可空禁用协议；保留 enabled/语义处理。默认轨道 63×28 不等于点击区域，外层仍需 48pt；必要时 reserveSwellRoom 防止膨胀裁切 |
| `GlassTabBar.bottom` | `LiquidGlassTabBar` | 使用公开普通构造器，不用已弃用 withImpeller。显式计算宽高、底部 margin、安全区和字号；保留双 Tab 状态与滚动位置，测试选中语义 |
| `GlassAppBar.pinned` / `GlassNavigationShell` | 保持透明标题布局，返回/操作用 easy 按钮；若需要整条玻璃胶囊则用 `LiquidGlassAppBar` | easy AppBar 不自动生成返回按钮，不是原 pinned 导航的替换件；显式接入返回、GoRouter 和草稿 PopScope。宽度不要沿用默认 360，按可用空间布局 |
| `GlassDialog` / `confirm` | `showLiquidGlassDialog` + `LiquidGlassAlertDialog` | 显式选择 barrierDismissible（默认 true），保留 bool 结果、危险操作与防误触；scrollable:true 并复测大字号、长消息及键盘 |
| `GlassPullDownButton` / `GlassMenu` | Flutter `PopupMenuButton` | 未找到一一对应的公开下拉菜单组件。保留外点关闭、焦点、编辑/删除、危险样式和返回关闭；不复制官方示例的整套动画菜单 |
| `GlassModalSheet` / `sheet` | 大表单默认普通底部面板；需玻璃时 `showLiquidGlassSheet` | easy 基于 showModalBottomSheet，支持键盘避让；无旧 medium/large detents 对应参数，确需两档再用 Flutter DraggableScrollableSheet 组合，不能假装字段等价 |
| `XField`、`GlassTextArea`、`GlassPasswordField` | Flutter TextField / TextFormField | 保留 maxLength、5 万字人设、密码遮挡、校验、输入法与滚动；不重写业务表单控制器 |
| `GlassPanel` / `GlassContainer.card` / `XTile` | 普通 DecoratedBox/Card、ListTile 等 | 保留设计色与圆角。大部分内容不再走玻璃层；删除专门的纯实色玻璃包装分支 |
| `GlassDivider` / `XLoading` / `GlassToast` | Divider、平台合适的进度与普通提示 | 不再为分隔线、错误提示与加载增加玻璃依赖 |

## 项目改动位置

生产依赖集中在 8 个 Dart 文件：

1. `lib/main.dart`：删除旧 initialize，若启用 shader 路径则使用 `LiquidGlassShaders.ensureLoaded()` 预热。
2. `lib/app/app.dart`：移除旧 wrap、adaptive scope、GlassNavigationShell；保留 MaterialApp.router、Riverpod、设备语言及前后台处理。
3. `lib/ui/core/design.dart`：保留颜色、字号、间距；移除旧主题、GlassQuality 和旧形状；只配置少量 easy 样式，页面通过公开导出访问组件。
4. `lib/ui/core/controls.dart`：在现有窄封装内替换按钮/开关，表单、列表及加载回归普通组件。不为每个样式新增一层控制器。
5. `lib/ui/core/widgets.dart`：XPage 用普通 Scaffold/Stack 管理全屏内容；confirm/sheet 改用上述协议。保留滚动 padding，不恢复上下 SafeArea 裁切和黑色整条渐暗。
6. `lib/ui/screens.dart`：迁移双 Tab 与两个菜单；移除普通卡片、头像、介绍横幅上的旧库引用。
7. `lib/ui/account_editor.dart`：普通表单和列表，指定开关/主操作保留玻璃；声音选择内容保持实色。
8. `lib/ui/call_history.dart`：保留首帧挂载顺序、取消晚到处理、挂断立即返回；控制按钮可玻璃，字幕/输入/历史为普通表面。多个按钮不要再层层包玻璃。

领域层、通话协调器、数据库、API Key、安全存储与业务接口无需随 UI 库迁移而改动。

## 迁移顺序

1. **更新约束。** 明确局部玻璃组件名单，更新 DECISIONS、UI 文档和 AST 门禁。删除“禁用所有可见 Material/Cupertino 控件”规则，改成“允许常规 UI、只在核心封装引用 easy、禁止旧库残留和自写折射器”；保留层依赖、凭证、覆盖率和异步等门槛。同步修改门禁反例测试，不通过关闭整个门禁解决。
2. **先验证一个页面。** 首页普通内容 + 固定 Tab、返回按钮、开关、确认弹窗作为试点；检查 iOS Impeller 与 Android 实际渲染路径。现有黑色与淡紫样式可保留，不把默认示例外观当成设计目标。
3. **替换核心封装及页面。** 删除旧 XButton/XField/XToggle/XPage，整理为明确用途的 App 控件；删除旧 Quality/全局玻璃基础设施和多余包装。先首页/设置，再编辑/弹层，最后通话。
4. **处理剩余平台差异。** 选择 Skia 只用磨砂降级，还是需要真正背景捕获；建议先用 Lite/磨砂降级，避免为了旧设备建立全屏持续截图管线。真实视频不使用捕获截图替代实时画面。
5. **清除旧依赖。** 移除 liquid_glass_widgets，固定经验证的 easy 版本并更新锁文件；用 Flutter 正常刷新 iOS 插件注册与 SPM 产物，不手改生成文件。不要长期同时加载两个玻璃 shader 系统。
6. **更新测试后分层验收。** 包类型断言换为项目控件语义/行为，保留原有通话、持久化、权限、键盘及全屏测试；使用独立命令更新黄金图并附并排对照。之后代码 check、双端 build、iOS 模拟器和可用 Android 设备离线回归，真实 RTC 合成另验。

## 需要先验证的风险

- **实时视频。** iOS 当前 Agora 使用 FlutterTexture，适合进入 Flutter 合成，仍需确认折射是否采到动态视频。Android 保留官方 TextureView 路径；新库未发现旧 platformViewBackdrop 的公开对等适配参数，不能保证原生画面可以被同样采样。若控制条读不到视频，先用 Lite/实色表面，不新增自定义桥接，不更换 RTC、不用静态图冒充。
- **无障碍。** 源码中按钮使用 InkWell，具有框架基础行为；开关和 Tab 未找到与旧库等价的显式 Semantics/减少动态处理。需验证并补全开关 toggled、Tab selected、禁用操作、读屏标签和焦点。未证明库自动处理减少透明度，不能删除项目相应策略。
- **布局。** 按钮、AppBar、Tab、开关都依赖显式尺寸。2 倍字号、320 宽手机和长英文要实际测；不能用缩放整个控件或禁用字体缩放掩盖溢出。全屏列表继续铺到状态栏及悬浮 Tab 后方。
- **渲染与测试。** 将测试固定旧 Standard 的机制换为明确的 Lite/磨砂宿主模式；Lite 匹配不代表 shader 折射通过。预热和 bundle 构建不证明帧率、原生视频兼容、iOS/Android 包构建或视觉效果；这些需分别记录。
- **复杂度。** easy 支持 Morph/Blender 等能力不代表项目需要它们。默认只用公开组件与普通 Flutter 菜单，禁止 src 导入和复制示例源码形成第二套库。

## 迁移前探针验证（历史记录）

在被忽略的 `build/harness/research/liquid_glass_easy_probe/` 建立了独立探针，不改变项目 pubspec/lock 或应用代码。探针包含普通 Scaffold/表单/卡片，以及 easy Button、Switch、AppBar、TabBar、AlertDialog、Sheet。

- 使用当前 Flutter/Dart：依赖解析成功。
- 探针 `flutter analyze --no-pub`：通过。
- 探针 `flutter build bundle --no-pub --target lib/main.dart --debug`：退出 0，10 个包内 shader 产物已生成。
- 当前项目静态分析：通过；本次未迁移应用，未重新执行 UI 验收、双端原生构建或真实收费通话。

上述仅证明当前工具链可解析 API、打包资源；不宣称迁移或设备验收已经完成。

## 官方来源

- [pub.dev 5.2.0](https://pub.dev/packages/liquid_glass_easy/versions/5.2.0)
- [pub.dev 官方示例](https://pub.dev/packages/liquid_glass_easy/example)
- [官方仓库与 README](https://github.com/AhmeedGamil/liquid_glass_easy)
- [官方文档与交互演示](https://ahmeedgamil.github.io/liquid_glass_easy/)

已通过 Dart MCP read_package_uris / rip_grep_packages 核对发布包 README、导出 API、组件实现及示例；以下载的 5.2.0 发布包为本次可重复核对的来源。在线主分支可能继续变化。
