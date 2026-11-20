/// Uses [GlobalMaterialLocalizations.delegate] and
/// [GlobalCupertinoLocalizations.delegate] from the standalone design libraries.
library;

// Flutter 3.50 gen-l10n still emits legacy delegate names. Import prefixes select
// the modern delegates without modifying the generator or its generated files.
import 'package:xiaoyu/l10n/material_delegate.dart'
    as GlobalMaterialLocalizations;
import 'package:xiaoyu/l10n/cupertino_delegate.dart'
    as GlobalCupertinoLocalizations;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Xiaoyu'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @headline.
  ///
  /// In en, this message translates to:
  /// **'A little company, a real conversation'**
  String get headline;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Choose a familiar voice. Share your day.'**
  String get tagline;

  /// No description provided for @myCharacters.
  ///
  /// In en, this message translates to:
  /// **'My companions'**
  String get myCharacters;

  /// No description provided for @createCharacter.
  ///
  /// In en, this message translates to:
  /// **'Create companion'**
  String get createCharacter;

  /// No description provided for @noCharacters.
  ///
  /// In en, this message translates to:
  /// **'Start with a portrait and a personality.'**
  String get noCharacters;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get account;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @localProfile.
  ///
  /// In en, this message translates to:
  /// **'Local profile'**
  String get localProfile;

  /// No description provided for @profileHint.
  ///
  /// In en, this message translates to:
  /// **'Your profile and companions stay on this device. Calls use your Vidu account.'**
  String get profileHint;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nickname;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Vidu API Key'**
  String get key;

  /// No description provided for @keyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your own API Key'**
  String get keyHint;

  /// No description provided for @keyConfigured.
  ///
  /// In en, this message translates to:
  /// **'API Key configured'**
  String get keyConfigured;

  /// No description provided for @keyMissing.
  ///
  /// In en, this message translates to:
  /// **'Set up your API Key'**
  String get keyMissing;

  /// No description provided for @rememberKey.
  ///
  /// In en, this message translates to:
  /// **'Save in secure system storage'**
  String get rememberKey;

  /// No description provided for @sameAccount.
  ///
  /// In en, this message translates to:
  /// **'This is the original Vidu account; keep resource links'**
  String get sameAccount;

  /// No description provided for @sameAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Turn this off for a new account. Existing companions keep their original account scope.'**
  String get sameAccountHint;

  /// No description provided for @checkKey.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get checkKey;

  /// No description provided for @keyChecked.
  ///
  /// In en, this message translates to:
  /// **'Authentication passed. This does not verify credits or RTC channel access.'**
  String get keyChecked;

  /// No description provided for @clearKey.
  ///
  /// In en, this message translates to:
  /// **'Clear API Key'**
  String get clearKey;

  /// No description provided for @clearKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Only the API Key is cleared. Companions, history and cloud resources remain. Pending calls still need the original account key.'**
  String get clearKeyHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @characterName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get characterName;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get summary;

  /// No description provided for @persona.
  ///
  /// In en, this message translates to:
  /// **'Prompt / personality'**
  String get persona;

  /// No description provided for @personaHint.
  ///
  /// In en, this message translates to:
  /// **'Describe identity, personality, speaking style and your relationship.'**
  String get personaHint;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @photoHint.
  ///
  /// In en, this message translates to:
  /// **'One person, PNG, JPG or WebP, under 20 MB. The original stays on this device.'**
  String get photoHint;

  /// No description provided for @uploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Create cloud avatar'**
  String get uploadAvatar;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @existingAvatars.
  ///
  /// In en, this message translates to:
  /// **'Choose an account avatar'**
  String get existingAvatars;

  /// No description provided for @noAvatars.
  ///
  /// In en, this message translates to:
  /// **'No avatar assets in this account'**
  String get noAvatars;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Greeting instructions'**
  String get greeting;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Remember our conversations'**
  String get memory;

  /// No description provided for @memoryHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, Vidu stores extracted memories in the cloud, scoped to this companion.'**
  String get memoryHint;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @saveCharacter.
  ///
  /// In en, this message translates to:
  /// **'Save companion'**
  String get saveCharacter;

  /// No description provided for @callCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a live conversation'**
  String get callCostTitle;

  /// No description provided for @callCostBody.
  ///
  /// In en, this message translates to:
  /// **'This uses your account credits. Billing starts when the control connection is ready. Each session lasts up to 2 hours; the platform ends it at the limit. Muting may still incur charges. The call ends when the app goes into the background or the screen locks. Microphone access is required; your camera stays off.'**
  String get callCostBody;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get endCall;

  /// No description provided for @returnToCall.
  ///
  /// In en, this message translates to:
  /// **'Return to call'**
  String get returnToCall;

  /// No description provided for @connectingHint.
  ///
  /// In en, this message translates to:
  /// **'Waiting for live audio and video. You can end at any time.'**
  String get connectingHint;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mutePlayback.
  ///
  /// In en, this message translates to:
  /// **'Mute sound'**
  String get mutePlayback;

  /// No description provided for @unmutePlayback.
  ///
  /// In en, this message translates to:
  /// **'Unmute sound'**
  String get unmutePlayback;

  /// No description provided for @audioRoute.
  ///
  /// In en, this message translates to:
  /// **'Audio output'**
  String get audioRoute;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @earpiece.
  ///
  /// In en, this message translates to:
  /// **'Earpiece'**
  String get earpiece;

  /// No description provided for @systemRoute.
  ///
  /// In en, this message translates to:
  /// **'System default / connected headset'**
  String get systemRoute;

  /// No description provided for @interrupt.
  ///
  /// In en, this message translates to:
  /// **'Interrupt'**
  String get interrupt;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Say something…'**
  String get chatHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @voiceAccepted.
  ///
  /// In en, this message translates to:
  /// **'Voice update accepted. It takes effect after the current reply.'**
  String get voiceAccepted;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No calls yet'**
  String get noHistory;

  /// No description provided for @usagePending.
  ///
  /// In en, this message translates to:
  /// **'Usage pending'**
  String get usagePending;

  /// No description provided for @checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check platform status'**
  String get checkStatus;

  /// No description provided for @endPending.
  ///
  /// In en, this message translates to:
  /// **'Local connections released. Platform ending is unconfirmed; billing may continue.'**
  String get endPending;

  /// No description provided for @unknownCreation.
  ///
  /// In en, this message translates to:
  /// **'Creation outcome unknown; no live ID received. Verify in the Vidu console before continuing.'**
  String get unknownCreation;

  /// No description provided for @localDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Delete this local companion. History and cloud avatars, knowledge and memories remain.'**
  String get localDeleteHint;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'About your data'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your API Key is only used to authenticate with Vidu. It is excluded from the chat database. Companions and chat text stay on this device. Live audio, persona and enabled knowledge and memory are sent to Vidu. Xiaoyu does not record entire calls.'**
  String get privacyBody;

  /// No description provided for @showKey.
  ///
  /// In en, this message translates to:
  /// **'Show or hide API Key'**
  String get showKey;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'Xiaoyu · Integration preview'**
  String get about;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'{phase, select, idle{Ready} creating{Connecting} initializing{Preparing} joining{Connecting media} connected{In call} ending{Ending} ended{Ended} pending{Ending unconfirmed} failed{Failed} uploading{Uploading photo} uploadFailed{Photo upload failed} uploadUnknown{Photo upload outcome unconfirmed} draft{Draft} created{Created} processing{Processing avatar} success{Avatar ready} other{Pending}}'**
  String status(String phase);

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Billed {seconds} seconds · {credits} credits'**
  String usage(int seconds, String credits);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'{code, select, missingKey{Set up your API Key first.} unauthorized{Invalid API Key. Please check it.} forbidden{This account cannot access the resource.} channelUnavailable{Agora is unavailable. Confirm channel access with Vidu.} insufficientCredit{Insufficient Vidu credits.} characterIncomplete{Complete the name, persona, ready avatar and compatible voice.} wrongCredential{This companion belongs to another credential profile. Restore its original profile.} microphoneDenied{Microphone permission is required. Allow it in system settings.} pendingCall{An earlier call has not been confirmed ended. Check History first.} prepareTimeout{Preparation timed out. Ending and checking status.} connectionLost{Connection lost. Ending and checking status.} notConnected{Connect a live call first.} actionCooldown{Wait two seconds before sending another action.} imageInvalid{Choose a supported image smaller than 20 MB.} inputInvalid{Check the input and its length.} voicePending{A voice update is awaiting confirmation.} voiceUnknown{Voice update outcome unknown. Change it in the next call.} voiceChangeFailed{Voice update failed. The accepted voice is unchanged.} commandRejected{The platform rejected the command.} notFound{Resource missing or temporarily unavailable.} protocol{The platform response is incompatible. Keep the pending record.} characterFieldsIncomplete{Enter a name and persona, choose a voice, and check the text length limits.} avatarUploadFailed{Photo upload failed. The original is saved. Submit again or recreate it in Advanced settings.} avatarImageChanged{The photo or account changed. Submit the current photo again.} avatarUploadUnknown{Photo upload outcome unknown. Check existing avatars in Advanced settings or recreate it manually.} avatarProcessing{Your cloud avatar is processing. Details are saved. Its status updates automatically; you can return Home.} avatarFailed{Cloud avatar processing failed. Recreate it in Advanced settings or choose another photo.}voiceInvalid{Voice and voice model do not match. Please choose again.}voiceChangeUnsupported{Doubao does not support changing voices during a call. Edit the character for the next call.}textChatUnsupported{This voice model does not support text chat. Speak directly or use quick actions.} other{The operation did not complete. Check the network or try later.}}'**
  String error(String code);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get unsavedChanges;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get continueEditing;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// No description provided for @unsavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Save your changes before leaving?'**
  String get unsavedDraft;

  /// No description provided for @knowledgeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Knowledge · Not available yet'**
  String get knowledgeUnavailable;

  /// No description provided for @voicePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Official voice directory · Preview is not available. Choosing a voice does not start a call.'**
  String get voicePreviewUnavailable;

  /// No description provided for @brandLine.
  ///
  /// In en, this message translates to:
  /// **'Every moment deserves to be heard'**
  String get brandLine;

  /// No description provided for @bannerBadge.
  ///
  /// In en, this message translates to:
  /// **'Warmth · Just for you'**
  String get bannerBadge;

  /// No description provided for @bannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Companionship that responds'**
  String get bannerTitle;

  /// No description provided for @bannerBody.
  ///
  /// In en, this message translates to:
  /// **'Create a companion for real-time conversation and connection'**
  String get bannerBody;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get comingSoon;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Discover companions'**
  String get recommended;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get advancedSettings;

  /// No description provided for @knowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get knowledge;

  /// No description provided for @chooseDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose document'**
  String get chooseDocument;

  /// No description provided for @voiceAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get voiceAll;

  /// No description provided for @voiceMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get voiceMine;

  /// No description provided for @voiceMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get voiceMale;

  /// No description provided for @voiceFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get voiceFemale;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @chosen.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get chosen;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create character'**
  String get createTitle;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// No description provided for @connectPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your conversation…'**
  String get connectPreparing;

  /// No description provided for @connectLoading.
  ///
  /// In en, this message translates to:
  /// **'Connecting your companion and voice'**
  String get connectLoading;

  /// No description provided for @cancelConnection.
  ///
  /// In en, this message translates to:
  /// **'Cancel connection'**
  String get cancelConnection;

  /// No description provided for @callOngoing.
  ///
  /// In en, this message translates to:
  /// **'In call'**
  String get callOngoing;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your day with someone who listens'**
  String get profileSubtitle;

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} companions'**
  String characterCount(int count);

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @voiceStyle.
  ///
  /// In en, this message translates to:
  /// **'Voice preset'**
  String get voiceStyle;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @keyboardChat.
  ///
  /// In en, this message translates to:
  /// **'Text chat'**
  String get keyboardChat;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @emptyTranscript.
  ///
  /// In en, this message translates to:
  /// **'No conversation recorded'**
  String get emptyTranscript;

  /// Built-in action button label. IDs follow QuickAction in presentation/quick_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'{id, select, watermelon{Watermelon} durian{Durian} lollipop{Lollipop} iceCream{Ice cream} apple{Apple} burger{Burger} fries{Fries} dumpling{Dumpling} crayfish{Crayfish} cola{Cola} seeds{Sunflower seeds} noodles{Noodles} grapes{Grapes} milkTea{Milk tea} pigtails{Pigtails} tuckHair{Tuck hair} highPonytail{High ponytail} hairBun{Hair bun} hairFlip{Hair flip} bowClip{Bow clip} braid{Braid} cap{Backward cap} twirlHair{Twirl hair} sunglasses{Sunglasses} lipstick{Lipstick} heart{Heart} microphone{Sing} winkPeace{Wink and peace} readComments{Read comments} dance{Gentle dance} tiltSmile{Tilt and smile} hug{Hug} salute{Playful salute} wave{Wave} pretendCry{Pretend crying} nervous{Nervous} twoHandCheeks{Cup both cheeks} cuteSequence{Cute sequence} pipa{Pipa} phoenixCrown{Phoenix crown} shyPeace{Shy peace sign} floralCoat{Floral coat} playfulFace{Playful face} pokeCheek{Poke cheek} shyFingers{Shy fingers} touchEar{Touch ear} thumbsUp{Thumbs up} thankYou{Thank you} relief{Wipe brow} massageShoulder{Massage shoulder} surrender{Cute surrender} drawHeart{Draw a heart} pokeScreen{Poke screen} adjustCollar{Adjust collar} realization{Realization} think{Thinking} quiet{Quiet} helpless{Helpless shrug} leanBack{Lean back} countFingers{Count fingers} turnAround{Turn around} stretch{Stretch} cheer{Cheer on} clap{Clap} follow{Follow gesture} supportSign{Support sign} snap{Snap fingers} blowKiss{Blow a kiss} wink{Wink} giggle{Giggle} tongue{Playful tongue} pretendAngry{Pretend angry} fingerGun{Finger heart gun} kissCamera{Kiss camera} pinkyPromise{Pinky promise} daydream{Daydream} sleepy{Sleepy} funnyFace{Funny face} handFrame{Hand frame} devilHorns{Devil horns} overheadCircle{Overhead circle} airplane{Airplane arms} claspFists{Clasp fists} elegant{Elegant pose} oneHip{Hand on hip} bothHips{Hands on hips} shadeEyes{Shade eyes} palmsUp{Palms up} foldHands{Fold hands} handOnHeart{Hand on heart} oneHandCheek{Cup one cheek} chinRest{Rest chin} lookDown{Look down} leanForward{Lean in} flex{Flex} doraemon{Doraemon} ultraman{Ultraman} pikachu{Pikachu} flowers{Flowers} cake{Small cake} selfie{Selfie} cat{Hold a cat} dog{Hold a puppy} smile{Smile} nod{Nod} peace{Peace sign} other{}}'**
  String quickActionName(String id);

  /// Built-in action full instruction sent through text_action. IDs follow QuickAction in presentation/quick_actions.dart.
  ///
  /// In en, this message translates to:
  /// **'{id, select, watermelon{Hold a slice of watermelon with both hands, take a small bite, and smile contentedly.} durian{Pick up a small piece of durian, smell it, then taste a small bite.} lollipop{Raise a lollipop, gently lick it, and look playfully at the camera.} iceCream{Bring an ice cream to your mouth and taste a small bite with a relaxed, happy expression.} apple{Pick up an apple with one hand, take a small bite, and chew naturally.} burger{Hold a burger with both hands, take a small bite, and look happily at the camera.} fries{Pick up a fry, put it in your mouth, chew gently, and smile.} dumpling{Lift a dumpling with chopsticks, blow gently on it, and taste it.} crayfish{Pick up a crayfish and mime peeling the shell and tasting the meat.} cola{Pick up a can of cola, take a sip, and gently put it down.} seeds{Bring a sunflower seed to your mouth, mime cracking it gently, and put down the shell.} noodles{Lift a few instant noodles with chopsticks, blow gently on them, and taste them.} grapes{Pick a grape from a bunch, eat it, and smile.} milkTea{Hold a milk tea with both hands, sip through the straw, then look up and smile.} pigtails{Raise both hands, part your hair to the sides, and mime tying it into pigtails.} tuckHair{Raise one hand, gently tuck loose hair behind your ear, and smile softly.} highPonytail{Gather your hair with both hands and mime tying a high ponytail behind your head.} hairBun{Gather your hair with both hands and mime arranging it into a bun on top of your head.} hairFlip{Gently turn your head, let your hair sway naturally, then look at the camera.} bowClip{Pick up a bow hair clip, gently clip it to the side of your hair, and adjust it.} braid{Separate one side of your hair into strands, look down, and mime gently braiding it.} cap{Pick up a baseball cap, put it on backward, and gently adjust it.} twirlHair{Twirl a lock of hair beside your face around a finger, tilt your head slightly, and look natural.} sunglasses{Take out sunglasses, unfold and put them on, then lightly adjust the frame while looking at the camera.} lipstick{Pick up lipstick, gently apply it to your lips, then press your lips together.} heart{Make a heart with both hands in front of your chest, smile, and look at the camera.} microphone{Hold a microphone near your mouth and mime singing expressively with gentle movement.} winkPeace{Lean slightly toward the camera, wink, and make a peace sign beside your face.} readComments{Lean forward slightly and look attentively below the camera as if reading comments.} dance{Move your shoulders and upper body gently to a light rhythm, letting your hands dance naturally.} tiltSmile{Tilt your head gently to one side, look at the camera, and smile naturally.} hug{Open your arms toward the camera, lean forward slightly, and look eager for a hug.} salute{Raise one hand beside your forehead in a salute and smile playfully.} wave{Raise one hand with your palm toward the camera and wave gently from side to side in greeting.} pretendCry{Look exaggeratedly upset and gently wipe the corner of your eye as if pretending to cry.} nervous{Bring your fingers near your mouth as if biting your nails, frown slightly, and look nervous.} twoHandCheeks{Gently cup both cheeks, lean slightly toward the camera, and smile sweetly.} cuteSequence{In sequence, tilt your head, wink, smile with closed lips, cup your cheeks, shrug, make a heart, reach for a hug, and wave.} pipa{Hold a pipa in front of you, support its neck with your left hand, and gently pluck the strings with your right.} phoenixCrown{Lift a red phoenix crown with both hands, gently put it on your head, and straighten both sides.} shyPeace{Lean toward the camera, make a peace sign beside your face, lower your head slightly, and smile shyly.} floralCoat{Pick up a northeastern Chinese floral padded coat, mime putting it on, and straighten the front.} playfulFace{Face the camera, raise your eyebrows, wink, and wrinkle your nose in a playful face.} pokeCheek{Gently poke your cheek with an index finger, tilt your head, and look cute.} shyFingers{Hold your hands in front of your chest, gently touch your index fingertips together, and look down shyly.} touchEar{Lightly touch your earlobe, briefly look away, then look shyly at the camera.} thumbsUp{Raise one hand toward the camera, give a thumbs up, and smile in approval.} thankYou{Press your palms together in front of your chest, nod gently, and look sincerely grateful.} relief{Gently wipe your forehead with the back of your hand, relax your shoulders, and look relieved.} massageShoulder{Gently massage the opposite shoulder and neck with one hand, tilt your head, and relax.} surrender{Raise both hands beside your shoulders, palms forward, with an innocent, playful expression.} drawHeart{Extend your index finger, slowly trace a heart in front of the camera, then smile and lower your hand.} pokeScreen{Bring your index finger toward the camera as if gently tapping the screen, and smile playfully.} adjustCollar{Look down at your collar, smooth and straighten it with both hands, then look up.} realization{Lightly pat your forehead, raise your eyebrows, and look as if you suddenly understand.} think{Rest an index finger beside your chin, glance slightly upward, and look thoughtful.} quiet{Hold an index finger upright in front of your lips, press your lips together gently, and signal quiet.} helpless{Spread your hands to either side, shrug lightly, and look helpless.} leanBack{Slowly lean back against the chair, relax your shoulders, and look at ease.} countFingers{Raise one hand in front of your chest and extend your fingers in order to count from one to five.} turnAround{If the frame has enough room, slowly turn around once and return to facing the camera.} stretch{Stretch both arms upward and gently extend your upper body, then lower your arms naturally.} cheer{Hold loose fists in front of your chest, move them gently up and down, and smile encouragingly.} clap{Clap gently a few times in front of your chest, smile, and nod in happy approval.} follow{Face the camera, point an index finger toward the bottom of the frame, and gesture to invite a follow.} supportSign{Raise a small support sign with both hands, show it to the camera, and smile encouragingly.} snap{Raise one hand beside your shoulder and mime snapping your thumb and middle finger once.} blowKiss{Touch your fingers lightly to your lips, then extend your hand toward the camera to blow a kiss.} wink{Lean slightly toward the camera, wink one eye, and smile.} giggle{Lightly cover your mouth, smile with your eyes, and let your shoulders move gently as you giggle.} tongue{Look at the camera, briefly stick out the tip of your tongue, then withdraw it with a playful expression.} pretendAngry{Put your hands on your hips, lean toward the camera, then point lightly toward it while pretending to be angry.} fingerGun{Make a finger gun with your thumb and index finger, point it lightly toward the camera, then smile and lower your hand.} kissCamera{Slowly lean toward the camera, gently purse your lips in a kiss, then move back naturally.} pinkyPromise{Extend your little finger toward the camera and move it gently as if inviting a pinky promise.} daydream{Rest your cheek on one hand, let your gaze drift, and look quiet and relaxed.} sleepy{Lower your head slightly, gently rub the corner of your eye with the back of your hand, then look up sleepily.} funnyFace{Gently pull down one lower eyelid with a finger and briefly stick out your tongue in a playful face.} handFrame{Make a frame with both thumbs and index fingers in front of your face, and look through it at the camera.} devilHorns{Raise both hands beside the top of your head and extend both index fingers to imitate little devil horns.} overheadCircle{Curve both arms above your head into a large circle and smile at the camera.} airplane{Extend both arms to the sides like airplane wings and tilt your body gently.} claspFists{Clasp your hands in front of your chest, brighten your eyes, and look happily expectant.} elegant{Lift one hand near your mouth, rest the other at your waist, and raise your head slightly with elegant playfulness.} oneHip{Rest one hand at your waist, let the other hang naturally, and turn slightly to one side.} bothHips{Rest both hands at your waist with elbows naturally outward, and look up at the camera.} shadeEyes{Hold one hand horizontally above your eyes as if shading them from sunlight, and look forward.} palmsUp{Spread both hands to the sides in front of your chest, palms up, with a relaxed expression.} foldHands{Fold your hands naturally in front of your knees, sit upright, and look calm.} handOnHeart{Place one hand gently on your chest, look at the camera, and appear sincere and gentle.} oneHandCheek{Support one cheek lightly with one hand and tilt your head slightly toward your palm.} chinRest{Rest your chin lightly on one hand and look thoughtfully toward the camera.} lookDown{Slowly lower your head, look down naturally, and pause briefly.} leanForward{Lean your upper body gently toward the camera and look as if listening attentively.} flex{Bend one arm with a loose fist, raise your upper arm, and pose as if showing your muscles.} doraemon{Lift a Doraemon plush to your chest with both hands, show it to the camera, then hug it gently.} ultraman{Pick up an Ultraman toy, show it in front of you to the camera, and move it gently.} pikachu{Hold a Pikachu plush beside your face with both hands and smile while showing it to the camera.} flowers{Take a bouquet from beside you, hold it in front of your chest with both hands, and gently offer it toward the camera.} cake{Hold a small cake with both hands at chest height and smile while showing it.} selfie{Take out a phone with its screen facing you, raise your arm slightly, and pose for a selfie.} cat{Gently hold a kitten in front of your chest, support its body with one hand, and stroke its back with the other.} dog{Gently hold a puppy in front of you, smile at the camera, and pet it softly.} smile{Look at me and smile naturally.} nod{Nod gently with a smile.} peace{Make a peace sign beside your face and smile at the camera.} other{}}'**
  String quickActionPrompt(String id);

  /// Horizontal quick action category labels.
  ///
  /// In en, this message translates to:
  /// **'{id, select, common{Common} food{Food & drink} appearance{Hair & style} expressions{Expressions} gestures{Gestures} props{Props} other{}}'**
  String quickActionCategory(String id);

  /// No description provided for @voiceQwen.
  ///
  /// In en, this message translates to:
  /// **'Qwen'**
  String get voiceQwen;

  /// No description provided for @voiceDoubao.
  ///
  /// In en, this message translates to:
  /// **'Doubao'**
  String get voiceDoubao;

  /// No description provided for @voiceCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {name}'**
  String voiceCurrent(String name);

  /// No description provided for @voiceSearch.
  ///
  /// In en, this message translates to:
  /// **'Search name, ID, style or language'**
  String get voiceSearch;

  /// No description provided for @voiceClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get voiceClearSearch;

  /// No description provided for @voiceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} matching voices'**
  String voiceCount(int count);

  /// No description provided for @voiceNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching voices. Try another keyword or provider.'**
  String get voiceNoResults;

  /// No description provided for @voiceDoubaoHint.
  ///
  /// In en, this message translates to:
  /// **'Doubao voices use the mainland service. Text chat and voice changes during a call are unavailable; speak to your character or use quick actions.'**
  String get voiceDoubaoHint;

  /// No description provided for @voiceSavedNotListed.
  ///
  /// In en, this message translates to:
  /// **'Saved voice “{voice}” is absent from the current directory. Its preference is preserved; platform availability needs confirmation. You can choose a listed voice.'**
  String voiceSavedNotListed(String voice);

  /// No description provided for @textChatUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This voice model does not support text chat. Speak directly or use quick actions.'**
  String get textChatUnsupported;

  /// No description provided for @voicePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play this preview. Please try again.'**
  String get voicePreviewFailed;

  /// No description provided for @voicePlayPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview {voice}'**
  String voicePlayPreview(String voice);

  /// No description provided for @voiceStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop previewing {voice}'**
  String voiceStopPreview(String voice);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
