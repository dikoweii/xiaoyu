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
  /// **'This uses your Vidu credits. Billing starts when the control connection is ready. The default limit is 10 minutes. Muting may still incur charges. The call ends when the app goes into the background or the screen locks. Microphone access is required; your camera stays off.'**
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

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Say something…'**
  String get chatHint;

  /// No description provided for @actionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe an action…'**
  String get actionHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Command sent'**
  String get sent;

  /// No description provided for @voiceAccepted.
  ///
  /// In en, this message translates to:
  /// **'Voice update accepted. It takes effect after the current reply.'**
  String get voiceAccepted;

  /// No description provided for @emptyTranscript.
  ///
  /// In en, this message translates to:
  /// **'Live transcriptions will appear here'**
  String get emptyTranscript;

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

  /// No description provided for @actionsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe an action. Results depend on the avatar; precise poses are not guaranteed.'**
  String get actionsHint;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'{phase, select, idle{Ready} creating{Connecting} initializing{Preparing} joining{Connecting media} connected{In call} ending{Ending} ended{Ended} pending{Ending unconfirmed} failed{Failed} draft{Draft} created{Created} processing{Processing avatar} success{Avatar ready} other{Pending}}'**
  String status(String phase);

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Billed {seconds} seconds · {credits} credits'**
  String usage(int seconds, String credits);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'{code, select, missingKey{Set up your API Key first.} unauthorized{Invalid API Key. Please check it.} forbidden{This account cannot access the resource.} channelUnavailable{Agora is unavailable. Confirm channel access with Vidu.} insufficientCredit{Insufficient Vidu credits.} characterIncomplete{Complete the name, persona, ready avatar and compatible voice.} wrongCredential{This companion belongs to another credential profile. Restore its original profile.} microphoneDenied{Microphone permission is required. Allow it in system settings.} pendingCall{An earlier call has not been confirmed ended. Check History first.} prepareTimeout{Preparation timed out. Ending and checking status.} connectionLost{Connection lost. Ending and checking status.} notConnected{Connect a live call first.} actionCooldown{Wait two seconds before sending another action.} imageInvalid{Choose a supported image smaller than 20 MB.} inputInvalid{Check the input and its length.} voicePending{A voice update is awaiting confirmation.} voiceUnknown{Voice update outcome unknown. Change it in the next call.} voiceChangeFailed{Voice update failed. The accepted voice is unchanged.} commandRejected{The platform rejected the command.} notFound{Resource missing or temporarily unavailable.} protocol{The platform response is incompatible. Keep the pending record.} other{The operation did not complete. Check the network or try later.}}'**
  String error(String code);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unsavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Save your changes as a draft before leaving.'**
  String get unsavedDraft;

  /// No description provided for @knowledgeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Knowledge · Not available yet'**
  String get knowledgeUnavailable;

  /// No description provided for @voicePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice preview is not available yet. Select a voice for calls.'**
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
