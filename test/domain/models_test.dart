import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/domain/models.dart';

void main() {
  const c = Character(
    id: 'c',
    name: '小遇',
    persona: ' original\ntext ',
    avatarId: 'a',
    assetStatus: 'success',
  );
  test('character roundtrip retains stable IDs and original persona', () {
    final changed = c.copyWith(
      credentialId: 'account',
      summary: 'intro',
      imagePath: 'photo.png',
      voice: 'Cherry',
      greeting: 'hello',
      memory: true,
      sourceImageUrl: 'https://example.invalid/a.png',
      officialRoleId: 'official',
    );
    expect(Character.fromJson(changed.toJson()).toJson(), changed.toJson());
    final session = buildSession(changed, 'profile');
    expect(session['avatar']['persona'], c.persona);
    expect(session['avatar']['greeting_instruction'], 'hello');
    expect(session['memory_retrieval']['agent_id'], c.id);
    expect(encodeJson({'a': 1}), '{"a":1}');
  });
  test('invalid lengths reject without truncating user data', () {
    for (final bad in [
      c.copyWith(name: ''),
      c.copyWith(name: 'a' * 31),
      c.copyWith(persona: 'a' * 50001),
      c.copyWith(greeting: 'a' * 201),
      c.copyWith(voice: ''),
      c.copyWith(assetStatus: 'failed'),
    ]) {
      expect(() => buildSession(bad, 'profile'), throwsA(isA<AppFailure>()));
    }
    expect(
      buildSession(
        c.copyWith(persona: 'a' * 50000),
        'profile',
      )['avatar']['persona'].length,
      50000,
    );
  });
  test('call snapshots preserve readiness and identity when updating', () {
    final s =
        CallSnapshot(
          callId: 'call',
          character: c,
          phase: CallPhase.joining,
        ).copyWith(
          phase: CallPhase.connected,
          liveId: 'live',
          controlReady: true,
          joined: true,
          published: true,
          audioReady: true,
          firstFrame: true,
          video: const RemoteVideo('room', 1),
          muted: true,
          route: 'earpiece',
          error: 'network',
          readyAt: DateTime.utc(2026),
          voice: 'Cherry',
        );
    final copy = s.copyWith();
    expect(copy.active && copy.interactive, isTrue);
    expect(copy.callId, 'call');
    expect(copy.video!.uid, 1);
    expect(copy.voice, 'Cherry');
    expect(copy.muted, isTrue);
    expect(copy.readyAt, s.readyAt);
    expect(() => jsonObject('bad'), throwsA(isA<AppFailure>()));
    expect(const AppFailure('network').toString(), 'AppFailure(network)');
  });
}
