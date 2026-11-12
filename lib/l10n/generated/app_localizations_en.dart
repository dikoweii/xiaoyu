// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Xiaoyu';

  @override
  String get home => 'Home';

  @override
  String get me => 'Me';

  @override
  String get headline => 'A little company, a real conversation';

  @override
  String get tagline => 'Choose a familiar voice. Share your day.';

  @override
  String get myCharacters => 'My companions';

  @override
  String get createCharacter => 'Create companion';

  @override
  String get noCharacters => 'Start with a portrait and a personality.';

  @override
  String get account => 'Account settings';

  @override
  String get settings => 'Settings';

  @override
  String get history => 'History';

  @override
  String get localProfile => 'Local profile';

  @override
  String get profileHint =>
      'Your profile and companions stay on this device. Calls use your Vidu account.';

  @override
  String get nickname => 'Your name';

  @override
  String get key => 'Vidu API Key';

  @override
  String get keyHint => 'Paste your own API Key';

  @override
  String get keyConfigured => 'API Key configured';

  @override
  String get keyMissing => 'Set up your API Key';

  @override
  String get rememberKey => 'Save in secure system storage';

  @override
  String get sameAccount =>
      'This is the original Vidu account; keep resource links';

  @override
  String get sameAccountHint =>
      'Turn this off for a new account. Existing companions keep their original account scope.';

  @override
  String get checkKey => 'Check connection';

  @override
  String get keyChecked =>
      'Authentication passed. This does not verify credits or RTC channel access.';

  @override
  String get clearKey => 'Clear API Key';

  @override
  String get clearKeyHint =>
      'Only the API Key is cleared. Companions, history and cloud resources remain. Pending calls still need the original account key.';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get characterName => 'Name';

  @override
  String get summary => 'Introduction';

  @override
  String get persona => 'Prompt / personality';

  @override
  String get personaHint =>
      'Describe identity, personality, speaking style and your relationship.';

  @override
  String get portrait => 'Portrait';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get photoHint =>
      'One person, PNG, JPG or WebP, under 20 MB. The original stays on this device.';

  @override
  String get uploadAvatar => 'Create cloud avatar';

  @override
  String get refresh => 'Refresh';

  @override
  String get existingAvatars => 'Choose an account avatar';

  @override
  String get noAvatars => 'No avatar assets in this account';

  @override
  String get voice => 'Voice';

  @override
  String get greeting => 'Greeting instructions';

  @override
  String get memory => 'Remember our conversations';

  @override
  String get memoryHint =>
      'When enabled, Vidu stores extracted memories in the cloud, scoped to this companion.';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get saveCharacter => 'Save companion';

  @override
  String get callCostTitle => 'Start a live conversation';

  @override
  String get callCostBody =>
      'This uses your Vidu credits. Billing starts when the control connection is ready. The default limit is 10 minutes. Muting may still incur charges. The call ends when the app goes into the background or the screen locks. Microphone access is required; your camera stays off.';

  @override
  String get endCall => 'End call';

  @override
  String get returnToCall => 'Return to call';

  @override
  String get connectingHint =>
      'Waiting for live audio and video. You can end at any time.';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get audioRoute => 'Audio output';

  @override
  String get speaker => 'Speaker';

  @override
  String get earpiece => 'Earpiece';

  @override
  String get systemRoute => 'System default / connected headset';

  @override
  String get interrupt => 'Interrupt';

  @override
  String get chat => 'Chat';

  @override
  String get actions => 'Actions';

  @override
  String get chatHint => 'Say something…';

  @override
  String get actionHint => 'Describe an action…';

  @override
  String get send => 'Send';

  @override
  String get sent => 'Command sent';

  @override
  String get voiceAccepted =>
      'Voice update accepted. It takes effect after the current reply.';

  @override
  String get emptyTranscript => 'Live transcriptions will appear here';

  @override
  String get noHistory => 'No calls yet';

  @override
  String get usagePending => 'Usage pending';

  @override
  String get checkStatus => 'Check platform status';

  @override
  String get endPending =>
      'Local connections released. Platform ending is unconfirmed; billing may continue.';

  @override
  String get unknownCreation =>
      'Creation outcome unknown; no live ID received. Verify in the Vidu console before continuing.';

  @override
  String get localDeleteHint =>
      'Delete this local companion. History and cloud avatars, knowledge and memories remain.';

  @override
  String get privacy => 'About your data';

  @override
  String get privacyBody =>
      'Your API Key is only used to authenticate with Vidu. It is excluded from the chat database. Companions and chat text stay on this device. Live audio, persona and enabled knowledge and memory are sent to Vidu. Xiaoyu does not record entire calls.';

  @override
  String get showKey => 'Show or hide API Key';

  @override
  String get about => 'Xiaoyu · Integration preview';

  @override
  String get actionsHint =>
      'Describe an action. Results depend on the avatar; precise poses are not guaranteed.';

  @override
  String status(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'idle': 'Ready',
      'creating': 'Connecting',
      'initializing': 'Preparing',
      'joining': 'Connecting media',
      'connected': 'In call',
      'ending': 'Ending',
      'ended': 'Ended',
      'pending': 'Ending unconfirmed',
      'failed': 'Failed',
      'draft': 'Draft',
      'created': 'Created',
      'processing': 'Processing avatar',
      'success': 'Avatar ready',
      'other': 'Pending',
    });
    return '$_temp0';
  }

  @override
  String usage(int seconds, String credits) {
    return 'Billed $seconds seconds · $credits credits';
  }

  @override
  String error(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'missingKey': 'Set up your API Key first.',
      'unauthorized': 'Invalid API Key. Please check it.',
      'forbidden': 'This account cannot access the resource.',
      'channelUnavailable':
          'Agora is unavailable. Confirm channel access with Vidu.',
      'insufficientCredit': 'Insufficient Vidu credits.',
      'characterIncomplete':
          'Complete the name, persona, ready avatar and compatible voice.',
      'wrongCredential': 'This companion belongs to another credential profile. Restore its original profile.',
      'microphoneDenied':
          'Microphone permission is required. Allow it in system settings.',
      'pendingCall':
          'An earlier call has not been confirmed ended. Check History first.',
      'prepareTimeout': 'Preparation timed out. Ending and checking status.',
      'connectionLost': 'Connection lost. Ending and checking status.',
      'notConnected': 'Connect a live call first.',
      'actionCooldown': 'Wait two seconds before sending another action.',
      'imageInvalid': 'Choose a supported image smaller than 20 MB.',
      'inputInvalid': 'Check the input and its length.',
      'voicePending': 'A voice update is awaiting confirmation.',
      'voiceUnknown':
          'Voice update outcome unknown. Change it in the next call.',
      'voiceChangeFailed':
          'Voice update failed. The accepted voice is unchanged.',
      'commandRejected': 'The platform rejected the command.',
      'notFound': 'Resource missing or temporarily unavailable.',
      'protocol':
          'The platform response is incompatible. Keep the pending record.',
      'other':
          'The operation did not complete. Check the network or try later.',
    });
    return '$_temp0';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get unsavedDraft => 'Save your changes as a draft before leaving.';

  @override
  String get knowledgeUnavailable => 'Knowledge · Not available yet';

  @override
  String get voicePreviewUnavailable =>
      'Voice preview is not available yet. Select a voice for calls.';

  @override
  String get brandLine => 'Every moment deserves to be heard';

  @override
  String get bannerBadge => 'Warmth · Just for you';

  @override
  String get bannerTitle => 'Companionship that responds';

  @override
  String get bannerBody =>
      'Create a companion for real-time conversation and connection';

  @override
  String get viewAll => 'View all';

  @override
  String get comingSoon => 'Not available yet';

  @override
  String get recommended => 'Discover companions';

  @override
  String get advancedSettings => 'Advanced settings';

  @override
  String get knowledge => 'Knowledge';

  @override
  String get chooseDocument => 'Choose document';

  @override
  String get voiceAll => 'All';

  @override
  String get voiceMine => 'Mine';

  @override
  String get voiceMale => 'Male';

  @override
  String get voiceFemale => 'Female';

  @override
  String get choose => 'Choose';

  @override
  String get chosen => 'Selected';

  @override
  String get createTitle => 'Create character';

  @override
  String get uploadPhoto => 'Upload photo';

  @override
  String get connectPreparing => 'Preparing your conversation…';

  @override
  String get connectLoading => 'Connecting your companion and voice';

  @override
  String get cancelConnection => 'Cancel connection';

  @override
  String get callOngoing => 'In call';

  @override
  String get profileSubtitle => 'Share your day with someone who listens';

  @override
  String characterCount(int count) {
    return '$count companions';
  }

  @override
  String get submit => 'Submit';

  @override
  String get more => 'More';

  @override
  String get voiceStyle => 'Voice preset';

  @override
  String get transcript => 'Transcript';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';
}
