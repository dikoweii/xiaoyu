# 小遇品牌素材

- `launch.jpg`：用户最新提供的 2026-11-12 2_25PM 启动图，848×1264，保留完整原图及文字，底部不再包含平台说明和版权文字。Android/iOS 共用此 Flutter 素材，iOS 原生 LaunchImage 同步转换为无损 PNG。
- `icon.png`：恢复用户最初提供的不带边框图，裁取中央 (29,29)–(995,995) 区域，缩放为无透明通道的 1024×1024 PNG。主体相对最初版本仅放大约 6%；供原生图标使用，不作为 Flutter 运行时素材打包。

Flutter 启动图恢复 contain 居中，再统一放大 1.06 倍，只裁切两侧少量背景；背景为 #08090D。320×568、360×800、402×874 手机均校验全部文字未被裁切。初始化完成即进入应用，没有人为倒计时。iOS LaunchScreen 使用相同图片及 aspect fit，图片视图宽高为窗口的 1.06 倍且居中，与 Flutter 构图一致。

原生图标使用 Lanczos 缩放：iOS 按 AppIcon.appiconset/Contents.json 的 size×scale 生成；Android mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi 分别为 48/72/96/144/192 像素。adaptive foreground 恢复最初版本的 432×432 满幅图片，只将源图主体轻微放大；最终外形由系统蒙版生成，不预裁切。

Android 12+ 原生启动页受系统 SplashScreen 规范限制，先显示品牌图标，再交给 Flutter 完整启动图。launch_icon 为 1152×1152，原图缩至 768×768 居中，保留系统圆形遮罩的安全空间；旧 Android 使用同一图标居中，不新增原生桥接或插件。
