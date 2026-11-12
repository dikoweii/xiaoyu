import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/call_coordinator.dart';
import '../data/character_repository.dart';
import '../data/local/call_store.dart';
import '../data/local/repositories.dart';
import '../data/services/vidu_api.dart';
import '../data/services/vidu_signaling.dart';
import '../data/services/agora_rtc.dart';
import '../data/services/official_catalog.dart';
import '../data/services/microphone_permission.dart';
import '../domain/models.dart';

class AppRuntime {
  AppRuntime(
    this.local,
    this.credentials,
    this.api,
    this.profileId, {
    CallCoordinator? callsOverride,
  }) {
    characters = CharacterRepository(local, credentials, api);
    calls =
        callsOverride ??
        CallCoordinator(
          api: api,
          store: DriftCallStore(local),
          signalFactory: ViduSignaling.new,
          rtcFactory: AgoraRtcSession.new,
          microphonePermission: MicrophonePermission.request,
        );
  }
  final LocalRepository local;
  final CredentialRepository credentials;
  final ViduApi api;
  final String profileId;
  late final CharacterRepository characters;
  late final CallCoordinator calls;
  static Future<AppRuntime> open() async {
    final local = await LocalRepository.open();
    final credentials = CredentialRepository(local);
    await credentials.load();
    return AppRuntime(local, credentials, ViduApi(), await local.profileId());
  }

  Future<void> reconcileKnownCalls() async {
    final rows = await local.db.select(local.db.calls).get();
    for (final row in rows.where(
      (r) => !r.endConfirmed && r.phase != 'failed',
    )) {
      if (row.liveId == null) {
        await DriftCallStore(local).update(row.id, {'phase': 'pending'});
        continue;
      }
      final credential = await credentials.forId(row.credentialId);
      if (credential == null) continue;
      try {
        await calls.reconcile(row.id, row.liveId!, credential);
      } on Object {
        /* Kept pending. */
      }
    }
  }
}

final runtimeProvider = Provider<AppRuntime>(
  (ref) => throw UnimplementedError('Bootstrap required'),
);
final charactersProvider = StreamProvider(
  (ref) => ref.watch(runtimeProvider).local.watchCharacters(),
);
final historyProvider = StreamProvider(
  (ref) => ref.watch(runtimeProvider).local.watchCalls(),
);
final officialCatalogProvider = FutureProvider((ref) {
  final catalog = OfficialCatalog();
  ref.onDispose(catalog.dispose);
  return catalog.load();
});
final messagesProvider = StreamProvider.family(
  (ref, String callId) =>
      ref.watch(runtimeProvider).local.watchMessages(callId),
);
final callProvider = StreamProvider<CallSnapshot>((ref) async* {
  final coordinator = ref.watch(runtimeProvider).calls;
  yield coordinator.snapshot;
  yield* coordinator.changes;
});
