part 'voice_catalog_data.g.dart';

enum VoiceProvider {
  qwenOmni('qwen_omni'),
  doubao('doubao');

  const VoiceProvider(this.apiValue);
  final String apiValue;
}

class VoiceSelection {
  const VoiceSelection(this.provider, this.id);
  final VoiceProvider provider;
  final String id;
}

class VoiceOption {
  const VoiceOption({
    required this.provider,
    required this.id,
    required this.name,
    required this.description,
    required this.languages,
    required this.languageSummary,
    this.trialUrl = '',
    this.avatarUrl = '',
  });
  final VoiceProvider provider;
  final String id, name, description, languages, languageSummary;
  final String trialUrl, avatarUrl;
  VoiceSelection get selection => VoiceSelection(provider, id);

  bool matches(String query) {
    final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final text = '$name $id $description $languages'.toLowerCase();
    return terms.every(text.contains);
  }
}

VoiceOption? findVoice(VoiceProvider provider, String id) {
  for (final voice in officialVoices) {
    if (voice.provider == provider && voice.id == id) return voice;
  }
  return null;
}

// Earlier releases offered these Qwen voices. Preserve saved preferences while
// making their absence from the current public catalog visible in the picker.
bool isCompatibleVoice(VoiceProvider provider, String id) =>
    findVoice(provider, id) != null ||
    (provider == VoiceProvider.qwenOmni && {'Cherry', 'Chelsie'}.contains(id));
