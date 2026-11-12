# 小遇实施决策

2026-11-09，用户确认：

- 产品名称为“小遇”，英文名暂用 Xiaoyu。
- 按 PRD 先跑通流程；有 Vidu API Key，运行时在 App 输入。
- cyber-xiaoya-live 仅作参考，不复用源码或素材。
- 官方形象指 Vidu 平台提供的官方形象，需要在 App 中选择；同时支持用户自建形象。

## 技术文档对照

收到的技术文档与旧项目 docs/TECHNICAL_ARCHITECTURE.md V1.2 内容一致。主技术栈与 PRD 一致。当前仓库副本已更正根目录工程、人设原文优先、M0 提前实现取消/结束核对与本地链接。

官方形象目录使用用户提供的 `https://service.vidu.cn/live/v1/keeper/avatar/roles`，通过 avatar_types=system 选择官方角色。2026-11-09 已验证匿名读取成功，当前返回 15 个角色，不使用用户浏览器 Cookie。此接口属于官网接口，独立封装以应对变更；官网角色 ID 不作为公开 API avatar ID，选中后下载图片并创建用户账号的 API 资产，尚待真实 Key 验证。

M0 必验：Agora 账号通道、无用户摄像头媒体链路、WS 协议 Ping/Pong 是否满足 15 秒活性要求、转写结构、准备期挂断、强杀回收与账单。收费会话只能由用户点击开始创建。

## 2026-11-09：改用 Agora 与 SPM

用户要求在火山不能直接使用 SPM 时采用声网。火山 Flutter 3.60.9 发布包只有 podspec，没有 Package.swift；Agora Flutter 6.6.4 发布包同时提供 SPM manifest，原生 SDK 固定 4.6.4，iris_method_channel 2.2.7 也支持 SPM。

已将会话创建改为 rtc.provider=agora，使用 joinChannelWithUserAccount 原样传递 Vidu 的字符串 user_id，麦克风上行开启、本地摄像头关闭。已移除火山 Flutter/原生依赖、专用 Maven 源、Jetifier 与 iOS Pods 集成，保留 pubspec.lock 和 SPM Package.resolved。

官方证据：
- Agora 发布包：pub.dev/packages/agora_rtc_engine/versions/6.6.4
- Flutter SPM manifest：github.com/AgoraIO-Extensions/Agora-Flutter-SDK/blob/main/ios/agora_rtc_engine/Package.swift
- 原生 SPM manifest：github.com/AgoraIO/AgoraRtcEngine_iOS/blob/main/Package.swift
- Vidu RTC 参数与凭证映射：platform.vidu.cn/vidu-stream/doc/s2-avatar/realtime/parameters

账号是否开通 Agora 以及真实音视频/计费仍以 App 内验证为准；503 时不自动重试创建或切到其他通道。

真机发现 permission_handler_apple 的 SPM manifest 将 PERMISSION_MICROPHONE 解析为 0，导致直接返回 denied 而不弹授权。首次媒体验证临时通过 AVFoundation MethodChannel 完成；随后删除该桥接，双端统一使用 permission_handler，曾通过项目内 Apple 插件副本规避配置发现问题。

## 2026-11-10：恢复 pub 官方权限依赖

重新核对 permission_handler 官方 SPM 文档：单一环境应用通过 Info.plist 声明权限即可，Xcode 直接启动的构建可显式配置 PERMISSION_HANDLER_INFO_PLIST，配置或环境变化后须刷新 SPM 缓存。无需复制 Apple 插件。已删除 third_party 副本与 dependency_overrides，恢复 pub 官方依赖；Dart 的 request 调用无需修改。不自动设置全局 launchctl 变量，不修改 pub 缓存，不引入 CocoaPods。操作说明见 [iOS 权限配置](IOS_PERMISSIONS.md)。

## 2026-11-10：本地 Harness 与界面边界

- 开发依赖 analyzer/args/crypto/yaml 分别提供 Dart AST、参数解析、摘要和配置解析；integration_test 使用 Flutter SDK 官方组件。无新增运行时依赖、RTC 切换、权限桥接或本地插件。官方来源：https://pub.dev/packages/analyzer 、https://dart.dev/tools 、https://docs.flutter.dev/testing/integration-tests 。复用现有包，未引入新的测试执行框架。
- LiveApi 移至 domain/call_ports；页面通过 Riverpod presentation 控制器操作仓储、凭证和通话。可注入 HTTP、Socket、RTC 只用于离线验证；生产默认实现不变。
- 有效行覆盖率排除 AST 确认的 `extends Table` 声明式 schema 行：Drift 生成器编译这些声明，运行时使用生成的列；仍统计同文件 AppDatabase 的迁移和运行逻辑。真实 SQLite 创建、约束、重开与持久化由行为测试验证，不调用 schema DSL getter 刷覆盖率。原生权限桥接依赖设备验证，不能以宿主单测冒充。
- 黄金图使用固定离线夹具，系统字体由宿主加载；不使用设计稿示例头像、历史、对话作为用户数据。首轮黄金图只防回退，视觉符合度仍待审查。

- 静态分析增加 unawaited_futures 与 avoid_void_async，导航异步返回显式处理；不增加 ignore。首次黄金基线为双平台 16 张，后续仅专用更新命令可更新。配置及依赖变更必须同时更新本决策文件；机器仅检查记录存在，真实性仍由评审核对。
- iOS 无线设备测试使用 Flutter 官方 `integration_test_driver` + `flutter drive --publish-port --no-uninstall-first`。当前 SDK 的 `flutter test` 不接受 publish-port，且默认可能卸载测试应用，故 Android 测试显式 no-uninstall；无需修改 SDK 或插件。官方参考：https://docs.flutter.dev/testing/integration-tests 、Flutter SDK packages/flutter_tools/lib/src/test/integration_test_device.dart。

- RTC 原生释放抛错后仍执行平台结束/账单核对，但当前协调器阻止再次创建通话，避免释放状态未知时建立另一个原生引擎；需重新启动进程恢复。已补行为断言。

## 2026-11-10：将 Skill 提示改为可检查的动态加载流程

原实现仅检查四个固定 Skill 文件存在，无法发现任务只读 xiaoyu-harness。改为从用户安装的 `.agents/skills/*/SKILL.md` 发现真实元数据，按任务种类、改动路径及显式主题/名称选择，skills --load 读取并输出原文，check 核对任务与文件摘要。全部现有专项技能可通过主题或名称选择；新安装技能自动进入目录，默认路由配置需显式维护。不新增包、不复制或替换用户的专项技能。相比仅在文档中列名，此方案可阻断缺失/过期的文件加载；相比自动执行 AI runner，保持现有本地 Harness 边界。CLI 文件读取不能证明模型遵循，skillApplication 不标记通过，自述不能充当 MCP 证据。新增必测 skills_test.dart 验证这些失败情形，不放宽原有检查。

## 2026-11-10：官方 Liquid Glass Widgets 统一 UI

用户明确指定所有可见控件使用 liquid_glass_widgets。固定官方 1.17.1 与 cupertino_icons（包内密码和导航图标字体所需），不引入其他玻璃库、不复制包源码。官方来源：https://pub.dev/packages/liquid_glass_widgets/versions/1.17.1 、发布包 README、ios/liquid_glass_widgets/Package.swift；Flutter >=3.41、Dart >=3.5、iOS15，与当前工具链及 SPM 相容。启动预热官方 shader，保留 MaterialApp.router 并仅提供透明 Material 基础设施。HTML 为外观基准，额外已有角色功能移至高级设置。实色内容也使用该库的 solid 表面；Premium 用于悬浮控件，测试固定 Standard，不能冒充设备 Premium 效果。相比继续自写 BackdropFilter，此次采用官方公开渲染层和组件；不新建原生桥接。iOS Agora 使用 SDK 已有 FlutterTexture（官方包 src/render/video_view_controller.dart）；Android 保留 TextureView 并使用玻璃库公开 platformViewBackdrop 路径，实际动态画面合成仍须设备验证。

## 2026-11-10 — 本轮仅验收手机竖屏

根据用户“去除大屏和旋转屏的兼容，先把 iOS 和 Android 做好”的最新指示，本轮适配矩阵收敛为 320×568、360×800、402×874 的手机竖屏。保留中文/英文、Android/iOS、1×/2×字体以及键盘操作可达性。移除 430×932 和横屏专项矩阵，不新增方向锁，不将未覆盖的大屏或横屏称为通过。此调整由用户授权，未降低业务覆盖率门槛。

高级设置弹层在页面退出动画期间可能继续重建，因此控制器在打开前捕获；弹层布局使用其自身的 BuildContext，避免读取已停用的编辑页祖先。FlutterError 不再被业务提示吞掉，测试和 MCP 能发现真正的 UI 编程错误。

## 2026-11-11：局部玻璃迁移到 liquid_glass_easy

用户明确授权使用 easy 官方公开 API 重构，不保留旧封装兼容，缺少组件使用 Flutter 自带组件。此决定取代此前全部使用 liquid_glass_widgets 的要求。固定官方 liquid_glass_easy 5.2.0；它只有 Flutter/meta 依赖，没有原生插件，不增加 Pods/SPM 项目或自定义桥接。cupertino_icons 继续用于系统风格图标。

已通过 Dart MCP 核对发布包公开导出、README、按钮、开关、AppBar、TabBar、Dialog 和 Sheet 的实现。来源：https://pub.dev/packages/liquid_glass_easy/versions/5.2.0 、https://pub.dev/packages/liquid_glass_easy/example 、https://github.com/AhmeedGamil/liquid_glass_easy 。采用 ensureLoaded 预热与独立镜片，不启用全屏 capture/View 或复杂 Morph/Blender。替代方案为继续旧库局部使用，但用户已明确选择迁移。

固定导航、玻璃按钮、开关和短确认采用 easy；卡片、表单、列表、大面板及菜单用 Flutter。AppButton 主提交实色、次操作可玻璃；无旧 Quality/主题/平台背景兼容分支。AST 门禁改为阻止旧依赖、私有 API 和自写玻璃渲染，不再禁止普通 Material/Cupertino 控件；覆盖率和其余质量门槛保持不变。增加对应门禁反例，非自动豁免。

宿主截图使用 Skia Lite，Impeller 设备使用实时背景路径；Android 视频按钮 Lite，不能据此宣称真实视频折射兼容。测试与模拟器只使用隔离数据，不创建收费 live。

## 2026-11-11：Scroll Edge 顶栏与系统返回手势

按用户要求，普通页面的胶囊 AppBar 改为 easy 5.2.0 公开的 `LiquidGlassScrollEdge`（top、soft、blur 6），内放 Flutter `NavigationToolbar` 标题、48 点返回按钮及操作按钮。背景渐淡，列表视口保持全屏，初始内容避开标题，滚动后进入模糊层；不自写 BackdropFilter、不新增依赖。首页/我的沿用全屏滚动与各自品牌/头像区，通话保留原视频及控制层。来源：https://pub.dev/documentation/liquid_glass_easy/latest/liquid_glass_easy/LiquidGlassScrollEdge-class.html 、官方 example/lib/scroll_edge_page.dart。相比预留顶栏高度，此方式让内容真正滚过顶栏背后。

项目已使用 go_router。18.1.3 的自动 app 检测引用 `material_ui.MaterialApp`，当前应用使用 Flutter SDK `MaterialApp`，自动回退到 NoTransitionPage，缺少 iOS 交互返回检测器。回归测试复现设置页边缘滑动无法 pop。各 GoRoute 显式使用 SDK `MaterialPage`，保留 pageKey/restorationId、系统平台过渡及 PopScope；不修改 pub 缓存、不增加全屏拖动监听。来源：go_router 发布包 lib/src/pages/material.dart、lib/src/builder.dart，Flutter SDK MaterialPage / CupertinoPageTransitionsBuilder 公开 API。

iOS 从左边缘右滑返回，短滑可取消；Android 使用系统返回。编辑页有未保存修改或任务进行中继续阻止直接离开，避免丢失内容；点击返回可确认保存草稿后退出。这是保留原有保护，不伪装成无条件返回。离线设备场景额外验证账号→设置→原 Tab 的返回链及 Scroll Edge 截图；不涉及收费通话。

## 2026-11-11：数字人菜单使用官方 Morph

按用户提供的官方 morph_page.dart 示例，将角色三点菜单从 PopupMenuButton 改为公开 `LiquidGlassMorph`：48 点按钮从原位置展开为仅有编辑、删除的玻璃面板，内容决定高度、右侧角锚定；接近底部向上展开，面板限制在安全区。Flutter 透明 Dialog 路由只负责覆盖卡片裁切、外部关闭及系统返回，不自己渲染玻璃。Reduce Motion 直接呈现最终形状，普通模式使用官方 plain 弹簧；不复制包实现、不加依赖、不引入全屏背景捕获。编辑继续现有路由，删除继续现有确认和控制器。此决定取代此前“菜单用 Flutter 普通弹出面板”的选择。来源：用户附件与官方 example/lib/morph_page.dart，以及 easy 5.2.0 的公开 LiquidGlassMorph / LiquidGlassMorphMotion API；经 Dart MCP 查阅发布包实现。

## 2026-11-11：精简首页入口和官方角色预填

按用户九项调整，新增角色统一放到品牌标题右侧，移除搜索、首张新增卡、推荐查看更多及卡片聊天/新增按钮。我的角色用懒加载横向列表，图片完整 contain 显示、文字移到下方；点击图片保留现有账号检查、收费确认和通话流程，菜单是独立命中区域。关闭时只有裸三点且保留 48 点触控区域，展开仍使用官方 Morph，仅编辑/红色删除文字。我的历史分割线移除，底部 Tab 去掉额外 24 点空白，保留系统安全区。

官方角色数据按当前公开目录实际响应核对（无 Cookie/Key）：https://service.vidu.cn/live/v1/keeper/avatar/roles?pager.page=0&pager.pagesz=1&avatar_types=system 。选用首个有 uri 的 profile_photos 项作为卡片和编辑图片，其 description 为卡片描述与预填简介。人设优先已有 system_prompt_override/system_prompt/persona；为空时按官方 description、attrs 中的性格、背景、身份、说话风格及 extra 行为准则/知识合并，不虚构人物资料。点击推荐创建本地 UUID 草稿，通过控制器保存并进入现有编辑页；不将网站角色 ID 当作 OpenAPI 图片资产 ID。官网 voice_library 的内部音色与当前 qwen_omni 公开音色不同，保留当前可用默认音色；图片上传、资产就绪校验沿用原流程。无依赖、数据库或原生接口变更。

替代方案为继续跳空白编辑页/使用官网原始 ID，但前者要求重复输入、后者混淆资源域，均不采用。用离线模板验证字段持久化、菜单与图片点击隔离、30 个角色横滑、图片 contain 与安全区；模拟通话不作为真实媒体证据。黄金图通过专用命令更新，人工视觉确认继续单列。

## 2026-11-11：图片叠层与紧凑菜单

按用户后续调整，取代上一版图下文字与实色底板：我的/推荐数字人统一使用 PortraitTile，按解码后的图片比例确定圆角图片边界，图片完整显示，名称/描述浮在图片底部，三点菜单在图片右上角独立响应。仅在图片内部叠渐变帮助文字阅读，无外围背景、边框或多余信息区。图片加载监听在更新/销毁时解绑；头像及图片卡复用来源选择和失败占位，删除不再需要的 Portrait.fit 参数及两套旧卡片样式。横向列表按图片实际宽度排布，保留懒加载。

Morph 菜单按当前语言、字体和字号测量最长文字，加少量内边距决定宽度；弹出方向按实际文本高度和可用安全区决定，移除固定 208 宽、176 高的估算。仍只提供编辑/红色删除，操作区域至少 48 点。不新增依赖或兼容分支。补充图片原始比例、圆角、叠层边界和中英文大字号菜单宽度回归；保留已有预填、删除确认和模拟通话测试。

## 2026-11-11：Tab 固定底部间距

按用户最终要求，Android/iOS 首页与我的 Tab 统一距屏幕底部 12 点，不依据系统底部安全区计算。删除安全区减值及平台分支，只保留固定内边距；顶部、左右及其他页面的安全区行为不变。采用真实布局，不用 Transform 位移，保证绘制、语义与触控区域一致。回归同时核对两平台 34 点安全区和零安全区，位置均为窗口高度减 12。

移动位置回归发现旧 Tab 语义覆盖层只有透传 Listener，点击可能误入下方推荐卡。改为同区域 GestureDetector 显式更新所选 Tab、阻断背景点击，保留唯一语义目标；验证切到“我的”后路由仍为首页且资料区实际可见。

经 Dart MCP 核对 easy 5.2.0 的公开 TabBar 文档及实现，独立 TabBar 会再消费 MediaQuery.padding.bottom，因此外层定位后对底部栏子树 removePadding(bottom)，避免安全区重复叠加造成胶囊裁切。此处仅调整布局环境，不修改包源码。

## 2026-11-11：恢复 Tab 组件原生拖动

用户反馈底部栏无法拖动切换，并要求删除自定义防点击穿透处理。核对官方 liquid_glass_easy 5.2.0 的 LiquidGlassTabBar 与 LiquidGlassAnimatedNavBar：Impeller 玻璃胶囊以内部 Listener 接收按下、移动、释放来完成拖动；项目此前覆盖其上的 opaque GestureDetector 只处理点击，导致库无法收到手势。本次移除该点击处理器，不增加防穿透层、不复制库的手势逻辑。无障碍层只保留语义操作与无回调的 translucent Listener，物理点击/拖动交由官方组件。底部固定 12 点及系统栏保持原样。

来源：https://pub.dev/packages/liquid_glass_easy ，通过 Dart MCP 读取官方包 liquid_glass_tab_bar.dart、liquid_glass_animated_nav_bar.dart 及 liquid_glass_nav_bar_icon_row.dart。库的宿主 Skia 降级版本只支持点击；拖动回归放在支持 Impeller 的离线设备测试，双向拖动后核对选中页、路由及零收费创建，不能用宿主 Widget 点击测试冒充拖动验证。

## 2026-11-11：取消按压覆盖及长按 Tooltip

用户要求所有按钮和数字人卡片不再出现淡白按压/长按覆盖，也不显示 Tooltip。核对 Flutter Material 和官方 liquid_glass_easy 的 LiquidGlassButton：玻璃按钮内部同样使用 InkWell，并非玻璃折射产生的白色遮罩。主题统一使用 NoSplash、透明 splash/highlight/hover 和按钮 overlayColor；现有带 foregroundColor 的 styleFrom 会自行生成覆盖色，因此四处本地按钮样式也显式使用透明 overlayColor，避免覆盖主题。保留玻璃材质、Tab 选中状态、禁用状态及既有手势。

应用 builder 使用 Flutter 官方 TooltipVisibility 关闭文字浮层；图标的用途改由 Icon.semanticLabel 表达，避免当前 SDK 隐藏 Tooltip 时同时移除其辅助语义。通话 PopupMenuButton 的 tooltip 设为空串，阻止默认提示回填。未增加手势拦截层，无依赖、原生或业务逻辑变更，保留用户设置的 Tab 底部 26 点。

来源：本机 Flutter 3.47.9 的 material/tooltip.dart、tooltip_visibility.dart、icon_button.dart、TextButton.styleFrom 与 FilledButton.styleFrom，以及通过 Dart MCP 读取的官方 liquid_glass_button.dart。补充文本/实色/玻璃/图标按钮、列表行及角色卡按下 100ms、持续 800ms 的像素一致性测试，并验证释放后回调、Tooltip 隐藏和读屏标签。

## 2026-11-11：精简历史记录列表

按用户最新要求重新设计“我的”历史记录及查看全部页面，取代 design.html 的大底板卡片。两处统一 16 点水平间距，删除历史行的实色卡片及内部额外水平内边距；行内保留 48 点头像、名称、时间、状态和进入详情箭头。时间与状态按可用宽度自然换行，名称最多两行，待核对/失败状态仍有文字提示。查看全部入口使用内容自适应的轻量文字按钮，不再固定 106 宽。

PageBody 增加 horizontal 参数，默认仍为 20，仅“我的”设为 16；全部记录使用 ListView.builder 懒加载，预览继续最多四条，详情页及删除/核对行为不变。没有添加分割线、额外业务入口或依赖。新增离线测试验证两处边距、预览数量、懒加载、详情导航和空态；增加双端完整历史列表黄金图，设计对照由独立命令生成，人工审查继续单列。

## 2026-11-11：恢复统一按压反馈，继续关闭 Tooltip

用户最新要求取代此前取消按压覆盖的决定。普通按钮、图标、列表和角色卡采用低透明度淡紫色；玻璃按钮采用更轻的淡白色；浅色主按钮使用深紫色以保持可见，危险操作使用淡红色。按下与持续长按共用同一覆盖色，释放后清除；继续使用 NoSplash，避免扩散水波纹。TooltipVisibility 保持关闭，保留图标语义标签，不新增长按动作。

复用 Flutter 官方主题及 ButtonStyle，玻璃按钮通过局部 Theme.highlightColor 配置官方 LiquidGlassButton 内部 InkWell，无复制包源码或增加手势拦截。来源：Flutter Material 主题/InkWell/ButtonStyle，以及 Dart MCP 核对的 liquid_glass_easy 5.2.0 liquid_glass_button.dart。没有新增依赖、原生或业务改动，保留 Tab 原生拖动及用户设置的底部 26 点。像素测试验证短按可见、长按一致、释放恢复与单次回调，另验证真实菜单长按不弹 Tooltip 且读屏标签保留。

## 2026-11-12：用户品牌启动图与应用图标

按用户指定的两张图片，第一张作为启动图，第二张生成 iOS 所有 AppIcon 尺寸、Android 密度图标及 adaptive icon。保留源图于 assets/branding，不使用 AI 重绘。图片边缘 #08090D 与应用底色一致，iOS storyboard 及 Flutter 使用 aspect fit/contain，避免不同比例手机裁切图片文字。移除 Flutter 默认透明占位启动图片与白色原生背景；不改变运行页面的系统栏配置。

启动时先显示 Flutter 品牌画面，再加载现有 shader 和本地 AppRuntime，成功后进入原应用并执行原有待核对通话恢复；不添加人工停留计时、不触发收费创建。失败仅显示本地化通用错误与显式重试，不打印底层错误。测试通过注入初始化 Future 验证等待、成功切换、只初始化一次及失败重试。未新增依赖、权限、Pods 或原生桥接；相比启动插件，直接使用现有 storyboard/Android 资源和 Flutter 图片即可满足。

官方来源：https://docs.flutter.dev/ui/assets/assets-and-images 、https://docs.flutter.dev/platform-integration/android/splash-screen 、https://developer.android.com/develop/ui/views/launch/splash-screen 、https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen 。Android 12+ 系统启动页只允许背景与受遮罩的图标，不能放完整海报，因此原生阶段用新图标，Flutter 首屏显示完整海报。原图自带中文文案按用户要求保留，不将其拆为系统语言文字。

## 2026-11-12：放大品牌图标与启动画面

按用户后续要求，启动图从 contain/aspect fit 改为 cover/aspect fill，保持比例铺满手机屏幕，将底部文字落在屏幕下方，取代此前保留整张背景的决定。Flutter 底部居中，iOS 手机竖屏等高缩放、左右裁切，构图一致。使用实际海报文字边界验证三种手机尺寸，所有文字保留、底部距边约 16–32 点；无固定高度、字体缩放限制或方向锁。

图标改用用户新增的弧形边框参考图，裁去外圈 80 像素空白后生成 1024 正方形，主体线性放大约 19%，保留细边框与圆角周围背景，不把示例图外部空白一起缩小进桌面图标。iOS/Android 各尺寸同步生成；adaptive foreground 将图像置于 108dp 画布中央 72dp，避免边框被系统额外放大后裁掉，最终形状遵从启动器蒙版。Android 系统启动图标保留原安全区。没有新增依赖、桥接或业务代码；继续采用 Flutter Image.fit 与系统原生资源，来源沿用上一条官方文档。

## 2026-11-12：恢复最初构图，仅轻微放大

用户认为上一轮过大，明确要求恢复到它之前的版本再小幅放大。本轮移除新增的弧形边框，恢复最初 1_02PM 图片，裁中央 966×966 后生成各平台尺寸，主体仅比最初放大约 6%。Android adaptive 图层也恢复原始满幅图像结构，不保留边框版的额外内边距。

启动图恢复 contain/aspect fit 居中，Flutter 图片统一缩放 1.06 倍、在窗口内裁切少量左右背景；iOS 图片视图居中、宽高为窗口 1.06 倍，使用 aspect fit，实现相同构图。取消铺满与底部对齐；三种手机尺寸仍验证文字完整、缩放幅度及启动等待/切换/失败重试。没有新增依赖、方向锁、原生桥接或业务变更，替代上一轮约 19% 的图标放大和启动图 cover。

## 2026-11-12：替换为 2_25PM 启动图

按用户最新图片替换 Android/iOS 共用的 Flutter launch.jpg，并同步 iOS 原生 LaunchImage PNG，保持现有 1.06 倍 contain/aspect fit 居中比例及应用图标。新图不含底部平台说明及版权文字，布局测试的实测文字边界同步至 y=1080。Android 12+ 原生阶段继续使用系统规定的图标启动页，Flutter 初始化首屏显示新图。无依赖、业务、权限或平台桥接变更。
