import 'dart:io';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/app/runtime.dart' as runtime;
import 'package:xiaoyu/data/local/database.dart';
import 'package:xiaoyu/data/local/repositories.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/domain/models.dart' as domain;
import 'package:xiaoyu/presentation/controllers.dart';
import 'package:xiaoyu/ui/call_history.dart';
import 'package:xiaoyu/ui/core/design.dart';
import 'package:xiaoyu/l10n/generated/app_localizations.dart';

import 'offline.dart';

const companion = domain.Character(
  id: 'fixture-character',
  name: '小遇',
  persona: 'A kind companion.',
  avatarId: 'offline-asset',
  credentialId: 'offline-account',
  assetStatus: 'success',
  summary: 'A quiet moment, a familiar voice.',
  imagePath: 'companion.png',
);

const officialCompanion = <String, dynamic>{
  'id': 'offline-role-1',
  'name': '离线角色 A',
  'image_uri': 'https://example.invalid/source.png',
  'description': '温柔耐心的朋友。',
  'profile_photos': [
    {'uri': 'https://example.invalid/profile.png', 'description': '一起分享生活的小事。'},
  ],
  'attrs': {
    'high_frequency_personality': ['温柔', '耐心'],
    'character_background': ['喜欢阅读'],
    'language_style': ['自然亲切'],
    'extra': {'base_rule': '耐心倾听', 'knowledge': '生活小技巧'},
  },
};

class Fixture {
  Fixture({
    this.locale = 'zh',
    this.phase = domain.CallPhase.idle,
    this.empty = false,
    this.longContent = false,
    this.state = 'data',
    this.callsOverride,
    this.screenAwake,
    this.historyCount = 1,
  });
  final CallCoordinator? callsOverride;
  final Future<void> Function(bool)? screenAwake;
  final String locale;
  final int historyCount;
  final String state;
  final domain.CallPhase phase;
  final bool empty, longContent;
  late AppDatabase db;
  late Directory dir;
  late runtime.AppRuntime app;
  late ProviderContainer container;
  Future<void> open() async {
    dir = Directory.systemTemp.createTempSync('xiaoyu-fixture-');
    File('test/assets/companion.png').copySync('${dir.path}/companion.png');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final local = LocalRepository(db, dir);
    final credentials = CredentialRepository(local, secure: MemorySecure());
    app = runtime.AppRuntime(
      local,
      credentials,
      ViduApi(client: offlineDio((_) => throw StateError('Unexpected HTTP'))),
      'offline-profile',
      callsOverride: callsOverride,
    );
    if (!empty) {
      await local.saveCharacter(
        companion.copyWith(
          name: longContent ? '这是一个很长的角色名字 Long Companion' : null,
        ),
      );
    }
    app.calls.snapshot = domain.CallSnapshot(
      phase: phase,
      character: companion,
      callId: phase == domain.CallPhase.idle ? null : 'offline-call',
      controlReady: phase == domain.CallPhase.connected,
    );
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        runtime.runtimeProvider.overrideWithValue(app),
        runtime.screenAwakeProvider.overrideWithValue(
          screenAwake ?? (_) async {},
        ),
        runtime.officialCatalogProvider.overrideWith(
          (ref) async => empty
              ? []
              : [
                  officialCompanion,
                  {'id': 'offline-role-2', 'name': '离线角色 B', 'image_uri': ''},
                ],
        ),
        presenceAnimationProvider.overrideWithValue(false),
        runtime.charactersProvider.overrideWith(
          (ref) => state == 'loading'
              ? const Stream.empty()
              : state == 'error'
              ? Stream.error(const domain.AppFailure('storage'))
              : local.watchCharacters(),
        ),
        historyProvider.overrideWith(
          (ref) => Stream.value(
            empty
                ? []
                : [
                    for (var index = 0; index < historyCount; index++)
                      CallRecord(
                        id: index == 0
                            ? 'offline-history'
                            : 'offline-history-$index',
                        character: companion,
                        phase: 'ended',
                        createdAt: DateTime.utc(
                          2026,
                          1,
                          1,
                          12,
                        ).subtract(Duration(hours: index)),
                        endConfirmed: true,
                        credentialId: 'offline-account',
                        billedSeconds: 12,
                        creditsCost: '18',
                      ),
                  ],
          ),
        ),
        messagesProvider.overrideWith(
          (ref, id) => Stream.value(
            empty
                ? []
                : [
                    ChatMessage(
                      'assistant',
                      longContent
                          ? List.filled(
                              15,
                              'A long conversation 很长的一段对话。',
                            ).join()
                          : '很高兴遇见你。',
                      'observed',
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  Widget widget({Widget? page}) {
    LiquidGlassEngine.liteGlassOnSkia = true;
    return UncontrolledProviderScope(
      container: container,
      child: page == null
          ? const XiaoyuApp()
          : MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: XiaoyuDesign.theme,
              home: page,
            ),
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    String route = '/',
    Widget? page,
  }) async {
    tester.platformDispatcher.localesTestValue = [Locale(locale)];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(widget(page: page));
    await tester.runAsync(
      () => precacheImage(
        FileImage(File('${dir.path}/companion.png')),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    if (page == null && route != '/') {
      unawaited(container.read(routerProvider).push(route));
    }
    await tester.pump();
    // Complete the SDK's platform transition without waiting for indefinite
    // loading spinners to settle.
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> close() async {
    await FileImage(File('${dir.path}/companion.png')).evict();
    container.dispose();
    await app.calls.dispose();
    app.api.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  }
}
