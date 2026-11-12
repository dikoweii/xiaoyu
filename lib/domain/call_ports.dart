import 'models.dart';

abstract interface class CallPersistence {
  Future<void> begin(String callId, Character character, Credential credential);
  Future<void> update(String callId, Json fields);
  Future<void> message(
    String callId,
    String id,
    String speaker,
    String text,
    String delivery,
  );
  Future<bool> hasUnresolved();
}

abstract interface class Signaling {
  Stream<Json> get events;
  Future<void> connect();
  void send(int type, Json payload);
  Future<void> close();
}

class RtcUpdate {
  const RtcUpdate({
    this.joined,
    this.published,
    this.audioReady,
    this.firstFrame,
    this.video,
    this.route,
    this.failure,
  });
  final bool? joined, published, audioReady, firstFrame;
  final RemoteVideo? video;
  final String? route, failure;
}

abstract interface class RtcSession {
  Stream<RtcUpdate> get events;
  Future<void> join(Json info);
  Future<void> mute(bool muted);
  Future<void> route(String route);
  Future<void> dispose();
}

abstract interface class LiveApi {
  Future<Json> createLive(Credential credential, Json body);
  Future<Json> getLive(Credential credential, String id);
}
