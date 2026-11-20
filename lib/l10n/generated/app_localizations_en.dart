/// Uses [GlobalMaterialLocalizations.delegate] and
/// [GlobalCupertinoLocalizations.delegate] from the standalone design libraries.
library;

// Flutter 3.50 gen-l10n still emits legacy delegate names. Import prefixes select
// the modern delegates without modifying the generator or its generated files.
import 'package:xiaoyu/l10n/material_delegate.dart'
    as GlobalMaterialLocalizations;
import 'package:xiaoyu/l10n/cupertino_delegate.dart'
    as GlobalCupertinoLocalizations;

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
      'This uses your account credits. Billing starts when the control connection is ready. Each session lasts up to 2 hours; the platform ends it at the limit. Muting may still incur charges. The call ends when the app goes into the background or the screen locks. Microphone access is required; your camera stays off.';

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
  String get mutePlayback => 'Mute sound';

  @override
  String get unmutePlayback => 'Unmute sound';

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
  String get chatHint => 'Say something…';

  @override
  String get send => 'Send';

  @override
  String get voiceAccepted =>
      'Voice update accepted. It takes effect after the current reply.';

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
      'uploading': 'Uploading photo',
      'uploadFailed': 'Photo upload failed',
      'uploadUnknown': 'Photo upload outcome unconfirmed',
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
      'characterFieldsIncomplete': 'Enter a name and persona, choose a voice, and check the text length limits.',
      'avatarUploadFailed': 'Photo upload failed. The original is saved. Submit again or recreate it in Advanced settings.',
      'avatarImageChanged':
          'The photo or account changed. Submit the current photo again.',
      'avatarUploadUnknown': 'Photo upload outcome unknown. Check existing avatars in Advanced settings or recreate it manually.',
      'avatarProcessing': 'Your cloud avatar is processing. Details are saved. Its status updates automatically; you can return Home.',
      'avatarFailed': 'Cloud avatar processing failed. Recreate it in Advanced settings or choose another photo.',
      'voiceInvalid':
          'Voice and voice model do not match. Please choose again.',
      'voiceChangeUnsupported': 'Doubao does not support changing voices during a call. Edit the character for the next call.',
      'textChatUnsupported': 'This voice model does not support text chat. Speak directly or use quick actions.',
      'other':
          'The operation did not complete. Check the network or try later.',
    });
    return '$_temp0';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get unsavedChanges => 'Save changes?';

  @override
  String get continueEditing => 'Keep editing';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get unsavedDraft => 'Save your changes before leaving?';

  @override
  String get knowledgeUnavailable => 'Knowledge · Not available yet';

  @override
  String get voicePreviewUnavailable =>
      'Official voice directory · Preview is not available. Choosing a voice does not start a call.';

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

  @override
  String get keyboardChat => 'Text chat';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get emptyTranscript => 'No conversation recorded';

  @override
  String quickActionName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'watermelon': 'Watermelon',
      'durian': 'Durian',
      'lollipop': 'Lollipop',
      'iceCream': 'Ice cream',
      'apple': 'Apple',
      'burger': 'Burger',
      'fries': 'Fries',
      'dumpling': 'Dumpling',
      'crayfish': 'Crayfish',
      'cola': 'Cola',
      'seeds': 'Sunflower seeds',
      'noodles': 'Noodles',
      'grapes': 'Grapes',
      'milkTea': 'Milk tea',
      'pigtails': 'Pigtails',
      'tuckHair': 'Tuck hair',
      'highPonytail': 'High ponytail',
      'hairBun': 'Hair bun',
      'hairFlip': 'Hair flip',
      'bowClip': 'Bow clip',
      'braid': 'Braid',
      'cap': 'Backward cap',
      'twirlHair': 'Twirl hair',
      'sunglasses': 'Sunglasses',
      'lipstick': 'Lipstick',
      'heart': 'Heart',
      'microphone': 'Sing',
      'winkPeace': 'Wink and peace',
      'readComments': 'Read comments',
      'dance': 'Gentle dance',
      'tiltSmile': 'Tilt and smile',
      'hug': 'Hug',
      'salute': 'Playful salute',
      'wave': 'Wave',
      'pretendCry': 'Pretend crying',
      'nervous': 'Nervous',
      'twoHandCheeks': 'Cup both cheeks',
      'cuteSequence': 'Cute sequence',
      'pipa': 'Pipa',
      'phoenixCrown': 'Phoenix crown',
      'shyPeace': 'Shy peace sign',
      'floralCoat': 'Floral coat',
      'playfulFace': 'Playful face',
      'pokeCheek': 'Poke cheek',
      'shyFingers': 'Shy fingers',
      'touchEar': 'Touch ear',
      'thumbsUp': 'Thumbs up',
      'thankYou': 'Thank you',
      'relief': 'Wipe brow',
      'massageShoulder': 'Massage shoulder',
      'surrender': 'Cute surrender',
      'drawHeart': 'Draw a heart',
      'pokeScreen': 'Poke screen',
      'adjustCollar': 'Adjust collar',
      'realization': 'Realization',
      'think': 'Thinking',
      'quiet': 'Quiet',
      'helpless': 'Helpless shrug',
      'leanBack': 'Lean back',
      'countFingers': 'Count fingers',
      'turnAround': 'Turn around',
      'stretch': 'Stretch',
      'cheer': 'Cheer on',
      'clap': 'Clap',
      'follow': 'Follow gesture',
      'supportSign': 'Support sign',
      'snap': 'Snap fingers',
      'blowKiss': 'Blow a kiss',
      'wink': 'Wink',
      'giggle': 'Giggle',
      'tongue': 'Playful tongue',
      'pretendAngry': 'Pretend angry',
      'fingerGun': 'Finger heart gun',
      'kissCamera': 'Kiss camera',
      'pinkyPromise': 'Pinky promise',
      'daydream': 'Daydream',
      'sleepy': 'Sleepy',
      'funnyFace': 'Funny face',
      'handFrame': 'Hand frame',
      'devilHorns': 'Devil horns',
      'overheadCircle': 'Overhead circle',
      'airplane': 'Airplane arms',
      'claspFists': 'Clasp fists',
      'elegant': 'Elegant pose',
      'oneHip': 'Hand on hip',
      'bothHips': 'Hands on hips',
      'shadeEyes': 'Shade eyes',
      'palmsUp': 'Palms up',
      'foldHands': 'Fold hands',
      'handOnHeart': 'Hand on heart',
      'oneHandCheek': 'Cup one cheek',
      'chinRest': 'Rest chin',
      'lookDown': 'Look down',
      'leanForward': 'Lean in',
      'flex': 'Flex',
      'doraemon': 'Doraemon',
      'ultraman': 'Ultraman',
      'pikachu': 'Pikachu',
      'flowers': 'Flowers',
      'cake': 'Small cake',
      'selfie': 'Selfie',
      'cat': 'Hold a cat',
      'dog': 'Hold a puppy',
      'smile': 'Smile',
      'nod': 'Nod',
      'peace': 'Peace sign',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String quickActionPrompt(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'watermelon': 'Hold a slice of watermelon with both hands, take a small bite, and smile contentedly.',
      'durian':
          'Pick up a small piece of durian, smell it, then taste a small bite.',
      'lollipop':
          'Raise a lollipop, gently lick it, and look playfully at the camera.',
      'iceCream': 'Bring an ice cream to your mouth and taste a small bite with a relaxed, happy expression.',
      'apple': 'Pick up an apple with one hand, take a small bite, and chew naturally.',
      'burger': 'Hold a burger with both hands, take a small bite, and look happily at the camera.',
      'fries': 'Pick up a fry, put it in your mouth, chew gently, and smile.',
      'dumpling':
          'Lift a dumpling with chopsticks, blow gently on it, and taste it.',
      'crayfish':
          'Pick up a crayfish and mime peeling the shell and tasting the meat.',
      'cola': 'Pick up a can of cola, take a sip, and gently put it down.',
      'seeds': 'Bring a sunflower seed to your mouth, mime cracking it gently, and put down the shell.',
      'noodles': 'Lift a few instant noodles with chopsticks, blow gently on them, and taste them.',
      'grapes': 'Pick a grape from a bunch, eat it, and smile.',
      'milkTea': 'Hold a milk tea with both hands, sip through the straw, then look up and smile.',
      'pigtails': 'Raise both hands, part your hair to the sides, and mime tying it into pigtails.',
      'tuckHair': 'Raise one hand, gently tuck loose hair behind your ear, and smile softly.',
      'highPonytail': 'Gather your hair with both hands and mime tying a high ponytail behind your head.',
      'hairBun': 'Gather your hair with both hands and mime arranging it into a bun on top of your head.',
      'hairFlip': 'Gently turn your head, let your hair sway naturally, then look at the camera.',
      'bowClip': 'Pick up a bow hair clip, gently clip it to the side of your hair, and adjust it.',
      'braid': 'Separate one side of your hair into strands, look down, and mime gently braiding it.',
      'cap':
          'Pick up a baseball cap, put it on backward, and gently adjust it.',
      'twirlHair': 'Twirl a lock of hair beside your face around a finger, tilt your head slightly, and look natural.',
      'sunglasses': 'Take out sunglasses, unfold and put them on, then lightly adjust the frame while looking at the camera.',
      'lipstick': 'Pick up lipstick, gently apply it to your lips, then press your lips together.',
      'heart': 'Make a heart with both hands in front of your chest, smile, and look at the camera.',
      'microphone': 'Hold a microphone near your mouth and mime singing expressively with gentle movement.',
      'winkPeace': 'Lean slightly toward the camera, wink, and make a peace sign beside your face.',
      'readComments': 'Lean forward slightly and look attentively below the camera as if reading comments.',
      'dance': 'Move your shoulders and upper body gently to a light rhythm, letting your hands dance naturally.',
      'tiltSmile': 'Tilt your head gently to one side, look at the camera, and smile naturally.',
      'hug': 'Open your arms toward the camera, lean forward slightly, and look eager for a hug.',
      'salute': 'Raise one hand beside your forehead in a salute and smile playfully.',
      'wave': 'Raise one hand with your palm toward the camera and wave gently from side to side in greeting.',
      'pretendCry': 'Look exaggeratedly upset and gently wipe the corner of your eye as if pretending to cry.',
      'nervous': 'Bring your fingers near your mouth as if biting your nails, frown slightly, and look nervous.',
      'twoHandCheeks': 'Gently cup both cheeks, lean slightly toward the camera, and smile sweetly.',
      'cuteSequence': 'In sequence, tilt your head, wink, smile with closed lips, cup your cheeks, shrug, make a heart, reach for a hug, and wave.',
      'pipa': 'Hold a pipa in front of you, support its neck with your left hand, and gently pluck the strings with your right.',
      'phoenixCrown': 'Lift a red phoenix crown with both hands, gently put it on your head, and straighten both sides.',
      'shyPeace': 'Lean toward the camera, make a peace sign beside your face, lower your head slightly, and smile shyly.',
      'floralCoat': 'Pick up a northeastern Chinese floral padded coat, mime putting it on, and straighten the front.',
      'playfulFace': 'Face the camera, raise your eyebrows, wink, and wrinkle your nose in a playful face.',
      'pokeCheek': 'Gently poke your cheek with an index finger, tilt your head, and look cute.',
      'shyFingers': 'Hold your hands in front of your chest, gently touch your index fingertips together, and look down shyly.',
      'touchEar': 'Lightly touch your earlobe, briefly look away, then look shyly at the camera.',
      'thumbsUp': 'Raise one hand toward the camera, give a thumbs up, and smile in approval.',
      'thankYou': 'Press your palms together in front of your chest, nod gently, and look sincerely grateful.',
      'relief': 'Gently wipe your forehead with the back of your hand, relax your shoulders, and look relieved.',
      'massageShoulder': 'Gently massage the opposite shoulder and neck with one hand, tilt your head, and relax.',
      'surrender': 'Raise both hands beside your shoulders, palms forward, with an innocent, playful expression.',
      'drawHeart': 'Extend your index finger, slowly trace a heart in front of the camera, then smile and lower your hand.',
      'pokeScreen': 'Bring your index finger toward the camera as if gently tapping the screen, and smile playfully.',
      'adjustCollar': 'Look down at your collar, smooth and straighten it with both hands, then look up.',
      'realization': 'Lightly pat your forehead, raise your eyebrows, and look as if you suddenly understand.',
      'think': 'Rest an index finger beside your chin, glance slightly upward, and look thoughtful.',
      'quiet': 'Hold an index finger upright in front of your lips, press your lips together gently, and signal quiet.',
      'helpless':
          'Spread your hands to either side, shrug lightly, and look helpless.',
      'leanBack': 'Slowly lean back against the chair, relax your shoulders, and look at ease.',
      'countFingers': 'Raise one hand in front of your chest and extend your fingers in order to count from one to five.',
      'turnAround': 'If the frame has enough room, slowly turn around once and return to facing the camera.',
      'stretch': 'Stretch both arms upward and gently extend your upper body, then lower your arms naturally.',
      'cheer': 'Hold loose fists in front of your chest, move them gently up and down, and smile encouragingly.',
      'clap': 'Clap gently a few times in front of your chest, smile, and nod in happy approval.',
      'follow': 'Face the camera, point an index finger toward the bottom of the frame, and gesture to invite a follow.',
      'supportSign': 'Raise a small support sign with both hands, show it to the camera, and smile encouragingly.',
      'snap': 'Raise one hand beside your shoulder and mime snapping your thumb and middle finger once.',
      'blowKiss': 'Touch your fingers lightly to your lips, then extend your hand toward the camera to blow a kiss.',
      'wink': 'Lean slightly toward the camera, wink one eye, and smile.',
      'giggle': 'Lightly cover your mouth, smile with your eyes, and let your shoulders move gently as you giggle.',
      'tongue': 'Look at the camera, briefly stick out the tip of your tongue, then withdraw it with a playful expression.',
      'pretendAngry': 'Put your hands on your hips, lean toward the camera, then point lightly toward it while pretending to be angry.',
      'fingerGun': 'Make a finger gun with your thumb and index finger, point it lightly toward the camera, then smile and lower your hand.',
      'kissCamera': 'Slowly lean toward the camera, gently purse your lips in a kiss, then move back naturally.',
      'pinkyPromise': 'Extend your little finger toward the camera and move it gently as if inviting a pinky promise.',
      'daydream': 'Rest your cheek on one hand, let your gaze drift, and look quiet and relaxed.',
      'sleepy': 'Lower your head slightly, gently rub the corner of your eye with the back of your hand, then look up sleepily.',
      'funnyFace': 'Gently pull down one lower eyelid with a finger and briefly stick out your tongue in a playful face.',
      'handFrame': 'Make a frame with both thumbs and index fingers in front of your face, and look through it at the camera.',
      'devilHorns': 'Raise both hands beside the top of your head and extend both index fingers to imitate little devil horns.',
      'overheadCircle': 'Curve both arms above your head into a large circle and smile at the camera.',
      'airplane': 'Extend both arms to the sides like airplane wings and tilt your body gently.',
      'claspFists': 'Clasp your hands in front of your chest, brighten your eyes, and look happily expectant.',
      'elegant': 'Lift one hand near your mouth, rest the other at your waist, and raise your head slightly with elegant playfulness.',
      'oneHip': 'Rest one hand at your waist, let the other hang naturally, and turn slightly to one side.',
      'bothHips': 'Rest both hands at your waist with elbows naturally outward, and look up at the camera.',
      'shadeEyes': 'Hold one hand horizontally above your eyes as if shading them from sunlight, and look forward.',
      'palmsUp': 'Spread both hands to the sides in front of your chest, palms up, with a relaxed expression.',
      'foldHands': 'Fold your hands naturally in front of your knees, sit upright, and look calm.',
      'handOnHeart': 'Place one hand gently on your chest, look at the camera, and appear sincere and gentle.',
      'oneHandCheek': 'Support one cheek lightly with one hand and tilt your head slightly toward your palm.',
      'chinRest': 'Rest your chin lightly on one hand and look thoughtfully toward the camera.',
      'lookDown':
          'Slowly lower your head, look down naturally, and pause briefly.',
      'leanForward': 'Lean your upper body gently toward the camera and look as if listening attentively.',
      'flex': 'Bend one arm with a loose fist, raise your upper arm, and pose as if showing your muscles.',
      'doraemon': 'Lift a Doraemon plush to your chest with both hands, show it to the camera, then hug it gently.',
      'ultraman': 'Pick up an Ultraman toy, show it in front of you to the camera, and move it gently.',
      'pikachu': 'Hold a Pikachu plush beside your face with both hands and smile while showing it to the camera.',
      'flowers': 'Take a bouquet from beside you, hold it in front of your chest with both hands, and gently offer it toward the camera.',
      'cake': 'Hold a small cake with both hands at chest height and smile while showing it.',
      'selfie': 'Take out a phone with its screen facing you, raise your arm slightly, and pose for a selfie.',
      'cat': 'Gently hold a kitten in front of your chest, support its body with one hand, and stroke its back with the other.',
      'dog': 'Gently hold a puppy in front of you, smile at the camera, and pet it softly.',
      'smile': 'Look at me and smile naturally.',
      'nod': 'Nod gently with a smile.',
      'peace': 'Make a peace sign beside your face and smile at the camera.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String quickActionCategory(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'common': 'Common',
      'food': 'Food & drink',
      'appearance': 'Hair & style',
      'expressions': 'Expressions',
      'gestures': 'Gestures',
      'props': 'Props',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get voiceQwen => 'Qwen';

  @override
  String get voiceDoubao => 'Doubao';

  @override
  String voiceCurrent(String name) {
    return 'Current: $name';
  }

  @override
  String get voiceSearch => 'Search name, ID, style or language';

  @override
  String get voiceClearSearch => 'Clear search';

  @override
  String voiceCount(int count) {
    return '$count matching voices';
  }

  @override
  String get voiceNoResults =>
      'No matching voices. Try another keyword or provider.';

  @override
  String get voiceDoubaoHint =>
      'Doubao voices use the mainland service. Text chat and voice changes during a call are unavailable; speak to your character or use quick actions.';

  @override
  String voiceSavedNotListed(String voice) {
    return 'Saved voice “$voice” is absent from the current directory. Its preference is preserved; platform availability needs confirmation. You can choose a listed voice.';
  }

  @override
  String get textChatUnsupported =>
      'This voice model does not support text chat. Speak directly or use quick actions.';

  @override
  String get voicePreviewFailed =>
      'Could not play this preview. Please try again.';

  @override
  String voicePlayPreview(String voice) {
    return 'Preview $voice';
  }

  @override
  String voiceStopPreview(String voice) {
    return 'Stop previewing $voice';
  }
}
