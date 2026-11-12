// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '小遇';

  @override
  String get home => '首页';

  @override
  String get me => '我的';

  @override
  String get headline => '遇见一份，随时可说的陪伴';

  @override
  String get tagline => '选一个熟悉的声音，聊聊今天。';

  @override
  String get myCharacters => '我的数字人';

  @override
  String get createCharacter => '新增数字人';

  @override
  String get noCharacters => '从一张照片、一段性格开始。';

  @override
  String get account => '账号设置';

  @override
  String get settings => '设置';

  @override
  String get history => '历史记录';

  @override
  String get localProfile => '本地个人资料';

  @override
  String get profileHint => '资料与角色保存在本机，通话由你的 Vidu 账号提供。';

  @override
  String get nickname => '你的称呼';

  @override
  String get key => 'Vidu API Key';

  @override
  String get keyHint => '粘贴自己的 API Key';

  @override
  String get keyConfigured => '已配置接入凭证';

  @override
  String get keyMissing => '尚未配置 API Key';

  @override
  String get rememberKey => '保存到系统安全存储';

  @override
  String get sameAccount => '这是原来的 Vidu 账号，保留资源关联';

  @override
  String get sameAccountHint => '新账号请关闭此项，旧角色不会自动关联到新账号。';

  @override
  String get checkKey => '检查连接';

  @override
  String get keyChecked => '鉴权通过。此检查不代表余额充足或声网通道已开通。';

  @override
  String get clearKey => '清除凭证';

  @override
  String get clearKeyHint => '仅清除接入凭证，保留本地角色、历史及云端资源。待核对通话仍需原账号凭证。';

  @override
  String get save => '保存';

  @override
  String get saved => '已保存';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get characterName => '名称';

  @override
  String get summary => '简介';

  @override
  String get persona => '提示词 / 角色设定';

  @override
  String get personaHint => '描述她的身份、性格、说话方式，以及你们的关系。';

  @override
  String get portrait => '形象原图';

  @override
  String get choosePhoto => '从相册选择';

  @override
  String get photoHint => '单人 PNG、JPG 或 WebP 图片，小于 20 MB。原图保存在本机。';

  @override
  String get uploadAvatar => '创建云端形象';

  @override
  String get refresh => '刷新状态';

  @override
  String get existingAvatars => '选择账号已有形象';

  @override
  String get noAvatars => '当前账号没有可用的形象资产';

  @override
  String get voice => '声音';

  @override
  String get greeting => '开场提示';

  @override
  String get memory => '记住我们的对话';

  @override
  String get memoryHint => '开启后，对话提炼的记忆保存在 Vidu 云端，并按当前角色隔离。';

  @override
  String get saveDraft => '保存草稿';

  @override
  String get saveCharacter => '保存数字人';

  @override
  String get callCostTitle => '开始一场实时陪伴';

  @override
  String get callCostBody =>
      '本次使用你的 Vidu 账号，控制链路准备就绪后开始计费。默认最多 10 分钟，静音仍可能计费；进入后台或锁屏会结束通话。首次通话需要麦克风权限，不开启摄像头。';

  @override
  String get endCall => '结束通话';

  @override
  String get returnToCall => '返回当前通话';

  @override
  String get connectingHint => '正在等待真实数字人音视频。你可以随时结束。';

  @override
  String get mute => '静音';

  @override
  String get unmute => '取消静音';

  @override
  String get audioRoute => '音频输出';

  @override
  String get speaker => '扬声器';

  @override
  String get earpiece => '听筒';

  @override
  String get systemRoute => '系统默认 / 已连接耳机';

  @override
  String get interrupt => '打断回复';

  @override
  String get chat => '聊天';

  @override
  String get actions => '动作';

  @override
  String get chatHint => '输入你想说的话…';

  @override
  String get actionHint => '描述希望她做的动作…';

  @override
  String get send => '发送';

  @override
  String get sent => '指令已发送';

  @override
  String get voiceAccepted => '声音设置已接受，当前回复结束后生效。';

  @override
  String get emptyTranscript => '真实转写将在这里显示';

  @override
  String get noHistory => '还没有通话记录';

  @override
  String get usagePending => '用量待更新';

  @override
  String get checkStatus => '核对平台状态';

  @override
  String get endPending => '本地已退出，平台结束状态待核对；不能确认已停止计费。';

  @override
  String get unknownCreation => '创建结果未知，未取得会话 ID。请在 Vidu 控制台核实后再继续。';

  @override
  String get localDeleteHint => '删除本地角色，保留历史与云端形象、知识库和记忆。';

  @override
  String get privacy => '关于数据';

  @override
  String get privacyBody =>
      'API Key 仅用于 Vidu 鉴权，不写入聊天数据库。角色与聊天原文保存在本机；实时音频、角色设定及启用的知识与记忆会发送到 Vidu。小遇不录制整场音视频。';

  @override
  String get showKey => '显示或隐藏 API Key';

  @override
  String get about => '小遇 · 接入验证版';

  @override
  String get actionsHint => '输入动作描述。效果取决于当前形象，不保证精确姿态。';

  @override
  String status(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'idle': '待开始',
      'creating': '正在连接',
      'initializing': '正在准备',
      'joining': '正在接入音视频',
      'connected': '通话中',
      'ending': '正在结束',
      'ended': '已结束',
      'pending': '结束待核对',
      'failed': '连接失败',
      'draft': '草稿',
      'created': '已创建',
      'processing': '形象处理中',
      'success': '形象已就绪',
      'other': '待处理',
    });
    return '$_temp0';
  }

  @override
  String usage(int seconds, String credits) {
    return '计费 $seconds 秒 · $credits 积分';
  }

  @override
  String error(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'missingKey': '请先配置 API Key。',
      'unauthorized': 'API Key 无效，请检查。',
      'forbidden': '当前账号无权访问该资源。',
      'channelUnavailable': '声网通道不可用，请向 Vidu 确认开通状态。',
      'insufficientCredit': 'Vidu 账号额度不足。',
      'characterIncomplete': '请补全名称、人设、就绪形象与兼容声音。',
      'wrongCredential': '此角色属于另一套凭证配置，请恢复原配置。',
      'microphoneDenied': '需要麦克风权限才能通话，请在系统设置中允许。',
      'pendingCall': '有尚未确认结束的通话，请先在历史中核对。',
      'prepareTimeout': '连接准备超时，正在结束并核对。',
      'connectionLost': '连接已中断，正在结束并核对。',
      'notConnected': '请先接通实时通话。',
      'actionCooldown': '请稍等两秒再发送动作。',
      'imageInvalid': '请选择支持的图片格式，且大小小于 20 MB。',
      'inputInvalid': '请检查输入内容及长度。',
      'voicePending': '有声音更新正在等待确认，请稍候。',
      'voiceUnknown': '声音更新结果未知，请在下次通话再调整。',
      'voiceChangeFailed': '声音更新失败，当前声音保持原设置。',
      'commandRejected': '平台未接受该指令。',
      'notFound': '资源不存在或暂不可查询。',
      'protocol': '平台响应格式暂不兼容，请保留待核对状态。',
      'other': '操作未完成，请检查网络或稍后重试。',
    });
    return '$_temp0';
  }

  @override
  String get confirm => '确认';

  @override
  String get unsavedDraft => '保存当前修改为草稿后返回。';

  @override
  String get knowledgeUnavailable => '知识库 · 暂未接入';

  @override
  String get voicePreviewUnavailable => '音色试听暂未接入，可选择通话音色';

  @override
  String get brandLine => '有你在的每一刻，都值得被倾听';

  @override
  String get bannerBadge => '温暖·专属陪伴';

  @override
  String get bannerTitle => '让陪伴，有回应';

  @override
  String get bannerBody => '创建属于你的数字人，开启实时语音与情绪共鸣';

  @override
  String get viewAll => '查看全部';

  @override
  String get comingSoon => '暂未开放';

  @override
  String get recommended => '推荐数字人';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get knowledge => '知识库';

  @override
  String get chooseDocument => '选择文档';

  @override
  String get voiceAll => '全部';

  @override
  String get voiceMine => '我的';

  @override
  String get voiceMale => '男声';

  @override
  String get voiceFemale => '女声';

  @override
  String get choose => '选择';

  @override
  String get chosen => '已选择';

  @override
  String get createTitle => '创建新角色';

  @override
  String get uploadPhoto => '上传照片';

  @override
  String get connectPreparing => '正在准备通话…';

  @override
  String get connectLoading => '正在连接数字人与音色';

  @override
  String get cancelConnection => '取消连接';

  @override
  String get callOngoing => '通话中';

  @override
  String get profileSubtitle => '把日常，说给懂你的人听';

  @override
  String characterCount(int count) {
    return '共 $count 位';
  }

  @override
  String get submit => '提交';

  @override
  String get more => '更多';

  @override
  String get voiceStyle => '官方音色';

  @override
  String get transcript => '对话记录';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';
}
