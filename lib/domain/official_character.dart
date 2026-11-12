import 'models.dart';

/// Website character metadata is a template, never an OpenAPI asset ID.
class OfficialCharacter {
  OfficialCharacter(this.data);
  final Json data;

  static String _text(Object? value) => value is String ? value.trim() : '';
  static Json _object(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
  static String _lines(Object? value) => value is List
      ? value.map(_text).where((s) => s.isNotEmpty).join('；')
      : _text(value);

  Json get _photo {
    final photos = data['profile_photos'];
    if (photos is List) {
      for (final photo in photos) {
        final item = _object(photo);
        if (_text(item['uri']).isNotEmpty) return item;
      }
    }
    return const {};
  }

  String get id => _text(data['id']);
  String get name => _text(data['name']);
  String get description => _text(_photo['description']);
  String get imageUrl {
    final photo = _text(_photo['uri']);
    return photo.isNotEmpty ? photo : _text(data['image_uri']);
  }

  String get persona {
    for (final key in ['system_prompt_override', 'system_prompt', 'persona']) {
      final value = _text(data[key]);
      if (value.isNotEmpty) return value;
    }
    final attrs = _object(data['attrs']);
    final extra = _object(attrs['extra']);
    return [
      _text(data['description']),
      for (final entry in {
        '性格': attrs['high_frequency_personality'],
        '背景': attrs['character_background'],
        '身份与职业': attrs['identity_and_occupation'],
        '说话风格': attrs['language_style'],
        '行为准则': extra['base_rule'],
        '知识与兴趣': extra['knowledge'],
      }.entries)
        if (_lines(entry.value).isNotEmpty)
          '${entry.key}：${_lines(entry.value)}',
    ].where((s) => s.isNotEmpty).join('\n\n');
  }

  Character draft(String draftId) => Character(
    id: draftId,
    name: name,
    persona: persona,
    summary: description,
    sourceImageUrl: imageUrl,
    officialRoleId: id,
  );
}
