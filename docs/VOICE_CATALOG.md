# 实时音色目录与接口映射

## 当前目录

小遇连接 `api.vidu.cn`，目录取自 Vidu 国内实时版页面：
https://platform.vidu.cn/vidu-stream/doc/voice-list

2026-11-17 快照包含 Qwen 56 个、豆包国内 293 个。官网载荷的 `ali` 映射为 API `qwen_omni`，`doubao3` 映射为国内 `doubao`；`doubao2` 是海外目录，`async` 属于非实时产品，均不加入当前选择。官网页面代码也按站点语言/区域区分国内与海外目录；小遇切换界面语言不会更换 API 区域。

保留官方名称、voice_type、风格、完整语种和语种摘要。官方没有统一性别字段，不推测性别，不保留失效的“男声/女声/我的”筛选入口；弹窗沿用原半屏圆角样式、紫色胶囊分类和紧凑行列表，只展示音色名称与选择按钮；不显示搜索、ID、语种、风格、计数或说明文字。元数据保留在目录数据中。豆包左侧头像可点击试听/停止；千问使用默认图标，点击试听/停止。试听不创建 live。

## 角色与请求

角色 JSON 同时保存 `voiceProvider` 和 `voice`，数据库仍使用既有 config JSON，不改表结构。旧记录缺少供应商时按原行为恢复为 `qwen_omni`，默认 Serena；选择其他供应商标签只是筛选，点选音色才一起提交供应商和 ID，关闭面板不会修改角色。

创建请求：

```json
{
  "voice_model": {"provider": "doubao"},
  "avatar": {
    "id": "<当前账号的形象资产>",
    "persona": "<人设原文>",
    "voice": "zh_female_vv_uranus_bigtts"
  }
}
```

其他必需参数由既有 `buildSession` 组合。`avatar.voice` 必须与 `voice_model.provider` 匹配，原始 ID 包含空格或大小写时原样保留。未知音色、非实时版音色及跨供应商组合在创建收费会话前拒绝。

旧版本列出的 Cherry、Chelsie 当前不在公开目录。为避免静默修改已有角色，保留这两个历史 Qwen 偏好，实际可用性待确认；不把它们作为当前目录选项推广。其实际可用性不由离线测试证明。当前不新增克隆音色查询或创建，不能把账号自定义音色接口当成完整预置音色接口。

## 供应商能力差异

依据实时版参数：
https://platform.vidu.cn/vidu-stream/doc/s2-avatar/realtime/parameters

- 创建后不能变更供应商，编辑角色只影响下一次通话。
- Qwen 支持 `text_dialog`（type 102）；豆包国内版不支持，输入面板改为说明文字，快捷动作仍使用 type 101。不将文字聊天偷换成仅朗读文本。
- 豆包国内版不支持通过 `session_update` 更改 `avatar.voice`，应用层拒绝该命令。Qwen 同供应商声音更新仍等待回执，不把接受配置当成已经听到新音色。
- 当前请求不发送豆包会忽略的 `vad`、`llm` 参数；国内记忆参数继续使用既有配置。

## 更新方式

不在 App 中抓取网页。目录生成使用 Python 标准库；试听使用支持 iOS SPM 的 audioplayers。更新时运行：

```sh
python3 tool/update_voice_catalog.py
dart format lib/domain/voice_catalog_data.g.dart
flutter test --no-pub test/domain/voice_catalog_test.dart
```

生成器只读取无需鉴权的官方目录，校验字段、供应商和唯一性后生成常量。文件记录来源、快照日期及内容 SHA-256。离线复现可用 `--input /path/to/official.html --date YYYY-MM-DD`。目录结构改变会报错，保留原文件；不要手改生成文件。官方数量有变化时，需要审查新增/移除项后同步调整目录验收数量。

## 验证边界

离线测试覆盖全部目录项的创建参数、错误组合拦截、旧记录恢复、数据库重开、选择/取消、完整列表滚动、豆包文字与换音色能力保护，以及页面布局。离线设备流程覆盖选择豆包、保存并重新进入编辑页，不使用真实 Key、不创建收费 live。

黄金图通过专门的 `golden-update` 命令更新；迁移时曾生成本地旧图与新旧对照。2026-11-18 按用户要求清理这些临时审查产物，当前基线保留在 `test/ui/goldens/`；旧图对照不再作为可核验的现存证据。

目录与参数一致不代表所有音色均通过真实平台声音验收；实际音色、麦克风、计费和持续通话仍需用户触发的真机验证。


## 豆包试听资源（2026-11-17）

用户提供的 Speakers 列表按 `VoiceType` 精确匹配当前 293 个豆包 ID，全部具有 `TrialURL` 和 `Avatar`。只保留匹配项的公开媒体地址到 `tool/voice_catalog/doubao_media.json`，不保存整个接口响应或账号元数据。生成器将地址合并到 `voice_catalog_data.g.dart` 的 `trialUrl`、`avatarUrl` 字段，后续重生成不会丢失；新目录中未匹配项保持无试听，不猜测链接。Qwen 音频已按下文的 code 映射合并，头像字段为空。

点击头像播放该音色 `TrialURL`；再次点击停止。快速切换只保留最后一次请求，切换分类、选择音色、关闭弹窗及 App 离开前台均停止。播放完成恢复图标，加载失败提示重试。头像加载失败保留渐变底色和播放按钮。URL 和头像不进入角色创建参数，不需要额外 TTS Key。

自动化验证使用假播放器、离线头像和本地合成 WAV，检查正确 URL、完成/失败、快速切换及释放资源；模拟器本地 WAV 播放不能代替全部远程样音的声音验收。


## 阿里试听资源（2026-11-17）

用户提供 HTML 表格，按每行 `<code>` 与现有音色 `voice_type` 精确匹配，保留大小写及 ID 内部空格。音频读取 `<audio src>`、惰性 `data-src` 或嵌套 `<source src>`；同一行重复地址去重，多个不同地址报错。表格 64 行，当前目录的 56 个千问音色全部匹配，其余行不加入目录。只合并音频，不覆盖官方名称或其他元数据；头像保持为空并复用现有默认渐变图标与试听按钮。豆包映射保持原值。

映射保存在 `tool/voice_catalog/ali_media.json`，默认重生成会同时合并两个供应商的媒体。导入新表格可运行 `python3 tool/update_voice_catalog.py --ali-input /path/to/table.html`，离线官方目录仍可用 `--input` 指定。音频链接只用于试听，不进入创建角色或 live 的参数。
