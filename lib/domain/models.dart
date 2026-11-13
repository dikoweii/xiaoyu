import 'dart:convert';

typedef Json = Map<String, dynamic>;

Json jsonObject(Object? value) => value is Map
    ? Map<String, dynamic>.from(value)
    : throw const AppFailure('protocol');

class AppFailure implements Exception {
  const AppFailure(this.code, {this.status, this.outcomeUnknown = false});
  final String code;
  final int? status;
  final bool outcomeUnknown;
  @override
  String toString() => 'AppFailure($code)';
}

class Credential {
  const Credential(this.id, this.key);
  final String id;
  final String key;
  @override
  String toString() => 'Credential($id, [redacted])';
}

class Character {
  const Character({
    required this.id,
    required this.name,
    required this.persona,
    this.credentialId = '',
    this.summary = '',
    this.imagePath = '',
    this.avatarId = '',
    this.assetStatus = 'draft',
    this.voice = 'Serena',
    this.greeting = '',
    this.memory = false,
    this.sourceImageUrl = '',
    this.officialRoleId = '',
  });
  final String id, name, persona, credentialId, summary, imagePath;
  final String avatarId, assetStatus, voice, greeting;
  final bool memory;
  final String sourceImageUrl, officialRoleId;
  bool get ready =>
      name.isNotEmpty &&
      persona.isNotEmpty &&
      avatarId.isNotEmpty &&
      assetStatus == 'success';

  Character copyWith({
    String? id,
    String? name,
    String? persona,
    String? credentialId,
    String? summary,
    String? imagePath,
    String? avatarId,
    String? assetStatus,
    String? voice,
    String? greeting,
    bool? memory,
    String? sourceImageUrl,
    String? officialRoleId,
  }) => Character(
    id: id ?? this.id,
    name: name ?? this.name,
    persona: persona ?? this.persona,
    credentialId: credentialId ?? this.credentialId,
    summary: summary ?? this.summary,
    imagePath: imagePath ?? this.imagePath,
    avatarId: avatarId ?? this.avatarId,
    assetStatus: assetStatus ?? this.assetStatus,
    voice: voice ?? this.voice,
    greeting: greeting ?? this.greeting,
    memory: memory ?? this.memory,
    sourceImageUrl: sourceImageUrl ?? this.sourceImageUrl,
    officialRoleId: officialRoleId ?? this.officialRoleId,
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'persona': persona,
    'credentialId': credentialId,
    'summary': summary,
    'imagePath': imagePath,
    'avatarId': avatarId,
    'assetStatus': assetStatus,
    'voice': voice,
    'greeting': greeting,
    'memory': memory,
    'sourceImageUrl': sourceImageUrl,
    'officialRoleId': officialRoleId,
  };
  factory Character.fromJson(Json j) => Character(
    id: j['id'] as String,
    name: j['name'] as String,
    persona: j['persona'] as String,
    credentialId: j['credentialId'] as String? ?? '',
    summary: j['summary'] as String? ?? '',
    imagePath: j['imagePath'] as String? ?? '',
    avatarId: j['avatarId'] as String? ?? '',
    assetStatus: j['assetStatus'] as String? ?? 'draft',
    voice: j['voice'] as String? ?? 'Serena',
    greeting: j['greeting'] as String? ?? '',
    memory: j['memory'] as bool? ?? false,
    sourceImageUrl: j['sourceImageUrl'] as String? ?? '',
    officialRoleId: j['officialRoleId'] as String? ?? '',
  );
}

enum CallPhase {
  idle,
  creating,
  initializing,
  joining,
  connected,
  ending,
  ended,
  pending,
  failed,
}

class RemoteVideo {
  const RemoteVideo(this.roomId, this.uid);
  final String roomId;
  final int uid;
}

class CallSnapshot {
  const CallSnapshot({
    this.phase = CallPhase.idle,
    this.callId,
    this.character,
    this.liveId,
    this.controlReady = false,
    this.joined = false,
    this.published = false,
    this.audioReady = false,
    this.firstFrame = false,
    this.video,
    this.muted = false,
    this.playbackMuted = false,
    this.route = 'speakerphone',
    this.error,
    this.readyAt,
    this.voice,
  });
  final CallPhase phase;
  final String? callId, liveId, error, voice;
  final Character? character;
  final bool controlReady, joined, published, audioReady, firstFrame, muted;
  final bool playbackMuted;
  final String route;
  final RemoteVideo? video;
  final DateTime? readyAt;
  bool get active => {
    CallPhase.creating,
    CallPhase.initializing,
    CallPhase.joining,
    CallPhase.connected,
    CallPhase.ending,
  }.contains(phase);
  bool get interactive => phase == CallPhase.connected && controlReady;
  CallSnapshot copyWith({
    CallPhase? phase,
    String? liveId,
    bool? controlReady,
    bool? joined,
    bool? published,
    bool? audioReady,
    bool? firstFrame,
    RemoteVideo? video,
    bool? muted,
    bool? playbackMuted,
    String? route,
    String? error,
    DateTime? readyAt,
    String? voice,
  }) => CallSnapshot(
    phase: phase ?? this.phase,
    callId: callId,
    character: character,
    liveId: liveId ?? this.liveId,
    controlReady: controlReady ?? this.controlReady,
    joined: joined ?? this.joined,
    published: published ?? this.published,
    audioReady: audioReady ?? this.audioReady,
    firstFrame: firstFrame ?? this.firstFrame,
    video: video ?? this.video,
    muted: muted ?? this.muted,
    playbackMuted: playbackMuted ?? this.playbackMuted,
    route: route ?? this.route,
    error: error ?? this.error,
    readyAt: readyAt ?? this.readyAt,
    voice: voice ?? this.voice,
  );
}

void validateCharacterDetails(Character c) {
  if (c.name.trim().isEmpty ||
      c.persona.trim().isEmpty ||
      c.name.runes.length > 30 ||
      c.persona.runes.length > 50000 ||
      c.greeting.runes.length > 200 ||
      c.voice.isEmpty) {
    throw const AppFailure('characterFieldsIncomplete');
  }
}

Json buildSession(Character c, String profileId) {
  validateCharacterDetails(c);
  if (!c.ready) throw const AppFailure('characterIncomplete');
  // User text is preserved verbatim; the wrapper is explicit and predictable.
  return {
    'model': 'vidu-s2',
    'call_mode': 'video',
    'resolution': '720p',
    'rtc': {'provider': 'agora'},
    'voice_model': {'provider': 'qwen_omni'},
    'avatar': {
      'id': c.avatarId,
      'persona': c.persona,
      'voice': c.voice,
      if (c.greeting.isNotEmpty) 'greeting_instruction': c.greeting,
    },
    'audio': {'enable_transcription': true},
    'action': {'enabled': true, 'library_id': '0'},
    if (c.memory)
      'memory_retrieval': {
        'enabled': true,
        'provider': 'vidu',
        'user_id': profileId,
        'agent_id': c.id,
        'enable_write': true,
      },
    'idle_timeout_seconds': 300,
    'enable_recording': false,
  };
}

String encodeJson(Json value) => jsonEncode(value);
