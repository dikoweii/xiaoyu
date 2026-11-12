import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/app/bootstrap.dart';
import 'package:xiaoyu/ui/core/design.dart';
import 'package:xiaoyu/app/runtime.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/data/local/database.dart';
import 'package:xiaoyu/data/local/repositories.dart';
import 'package:xiaoyu/data/local/call_store.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/domain/call_ports.dart';
import 'package:xiaoyu/ui/integrations/rtc_video_surface.dart';

import '../test/support/offline.dart';
import '../test/application/call_coordinator_test.dart' as fake;

/// Persisted sessions need distinct platform IDs, just like real creations.
class _OfflineLiveApi extends fake.FakeApi {
  @override
  Future<Json> createLive(Credential credential, Json body) async {
    final response = await super.createLive(credential, body);
    return {
      ...response,
      'live': {...jsonObject(response['live']), 'id': 'offline-live-$creates'},
    };
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LiquidGlassShaders.ensureLoaded();
    LiquidGlassEngine.liteGlassOnSkia = true;
    // iOS may request its own semantics handle after the first tree is sent.
    // Complete that handshake before testWidgets records its leak baseline.
    final warmup = binding.ensureSemantics();
    try {
      runApp(const SizedBox());
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } finally {
      warmup.dispose();
    }
  });
  testWidgets(
    'offline navigation, SQLite recovery, permission status and simulated lifecycle',
    (tester) async {
      final dir = await Directory.systemTemp.createTemp(
        'xiaoyu-device-offline-',
      );
      AppDatabase open() => AppDatabase.forTesting(
        NativeDatabase(File('${dir.path}/offline.sqlite')),
      );
      var db = open();
      var local = LocalRepository(db, dir);
      // Generated offline artwork belongs only to this isolated test profile.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 300, 500),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF846B87), Color(0xFF252034)],
          ).createShader(const Rect.fromLTWH(0, 0, 300, 500)),
      );
      canvas.drawOval(
        const Rect.fromLTWH(85, 75, 130, 210),
        Paint()..color = const Color(0xFFE4C5D4),
      );
      canvas.drawOval(
        const Rect.fromLTWH(25, 275, 250, 400),
        Paint()..color = const Color(0xFF746087),
      );
      final picture = recorder.endRecording();
      final portrait = await picture.toImage(300, 500);
      final png = await portrait.toByteData(format: ui.ImageByteFormat.png);
      await File('${dir.path}/portrait.png')
          .writeAsBytes(png!.buffer.asUint8List());
      portrait.dispose();
      picture.dispose();
      final character = fake.character.copyWith(imagePath: 'portrait.png');
      await local.saveCharacter(character);
      final profile = await local.profileId();
      await db.close();
      db = open();
      local = LocalRepository(db, dir);
      expect(
        (await local.character(fake.character.id))!.persona,
        fake.character.persona,
      );
      expect(await local.profileId(), profile);
      final status = await Permission.microphone.status;
      expect(
        PermissionStatus.values,
        contains(status),
      ); // Read only: never requests or resets permission.
      final api = ViduApi(
        client: offlineDio((_) => throw StateError('Real HTTP forbidden')),
      );
      final signal = fake.FakeSignal(),
          rtc = fake.FakeRtc()..firstFrame = false,
          live = _OfflineLiveApi();
      final coordinator = CallCoordinator(
        api: live,
        store: DriftCallStore(local),
        signalFactory: (_, _) => signal.closed ? fake.FakeSignal() : signal,
        rtcFactory: () => rtc.disposals > 0 ? fake.FakeRtc() : rtc,
        microphonePermission: () async => true,
        queryDelays: [],
      );
      final app = AppRuntime(
        local,
        CredentialRepository(local, secure: MemorySecure()),
        api,
        profile,
        callsOverride: coordinator,
      );
      final container = ProviderContainer(
        overrides: [
          runtimeProvider.overrideWithValue(app),
          officialCatalogProvider.overrideWith(
            (ref) async => [
              for (var i = 0; i < 4; i++)
                {
                  'id': 'offline-role-$i',
                  'name': 'Offline $i',
                  'image_uri': '',
                  'system_prompt': 'Offline companion prompt $i',
                },
            ],
          ),
        ],
      );
      final ready = Completer<Widget>();
      var initializationStarted = false;
      await tester.pumpWidget(
        XiaoyuBootstrap(
          initialize: () {
            initializationStarted = true;
            return ready.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pump();
      }
      expect(initializationStarted, isTrue);
      expect(find.byKey(const Key('launch-artwork')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('offline-launch');
      ready.complete(
        UncontrolledProviderScope(
          container: container,
          child: const XiaoyuApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('launch-artwork')), findsNothing);
      final qualities = <String, String>{};
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        qualities[name] = ui.ImageFilter.isShaderFilterSupported
            ? 'impeller-live-backdrop'
            : 'skia-lite';
        await binding.takeScreenshot('offline-$name');
      }

      await capture('home');
      await tester.tap(find.byKey(const Key('character-menu')).hitTestable());
      await capture('character-menu');
      expect(find.byKey(const Key('menu-edit')).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('menu-delete')).hitTestable(),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('character-menu-panel')), findsNothing);
      final recommended = find.byKey(const Key('official-offline-role-0'));
      await Scrollable.ensureVisible(
        tester.element(recommended),
        alignment: .15,
      );
      await tester.pumpAndSettle();
      await tester.tap(recommended.hitTestable());
      await tester.pumpAndSettle();
      final imported = (await local.watchCharacters().first).singleWhere(
        (c) => c.officialRoleId == 'offline-role-0',
      );
      expect(imported.name, 'Offline 0');
      expect(imported.persona, 'Offline companion prompt 0');
      expect(
        container.read(routerProvider).state.uri.path,
        '/edit/${imported.id}',
      );
      await capture('official-prefill');
      container.read(routerProvider).pop();
      await tester.pumpAndSettle();
      final carousel = find.byKey(
        const PageStorageKey('my-characters-carousel'),
      );
      await tester.ensureVisible(carousel);
      await tester.pumpAndSettle();
      await tester.drag(carousel, const Offset(-260, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .state<ScrollableState>(
              find.descendant(of: carousel, matching: find.byType(Scrollable)),
            )
            .position
            .pixels,
        greaterThan(0),
      );
      await tester.drag(carousel, const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(live.creates, 0);
      await tester.drag(
        find.byType(ListView).hitTestable().first,
        const Offset(0, -180),
      );
      await capture('home-scrolled');
      final homeScroll = tester.state<ScrollableState>(
        find.byType(Scrollable).hitTestable().first,
      );
      expect(homeScroll.position.pixels, greaterThan(0));
      // Exercise the library's live glass-pill gestures on Impeller. The host
      // Skia fallback supports taps only and cannot verify this interaction.
      if (ui.ImageFilter.isShaderFilterSupported) {
        Future<void> dragTab(int from, int to) async {
          final start = tester.getCenter(find.byKey(Key('tab-$from')));
          final end = tester.getCenter(find.byKey(Key('tab-$to')));
          final gesture = await tester.startGesture(start);
          await tester.pump(const Duration(milliseconds: 100));
          for (var step = 1; step <= 12; step++) {
            await gesture.moveTo(Offset.lerp(start, end, step / 12)!);
            await tester.pump(const Duration(milliseconds: 16));
          }
          await gesture.up();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<LiquidGlassTabBar>(find.byType(LiquidGlassTabBar))
                .selectedIndex,
            to,
          );
          expect(container.read(routerProvider).state.uri.path, '/');
          expect(live.creates, 0);
        }

        await dragTab(0, 1);
        expect(find.text('本地个人资料').hitTestable(), findsOneWidget);
        await dragTab(1, 0);
        await capture('home-tab-drag');
      }
      await tester.tap(find.byKey(const Key('tab-1')).hitTestable());
      await tester.pumpAndSettle();
      await capture('me');
      final router = container.read(routerProvider);
      unawaited(router.push('/settings'));
      await capture('settings');
      unawaited(router.push('/account'));
      await capture('account');
      Future<void> back() async {
        if (Platform.isIOS) {
          final size = tester.getSize(find.byType(MaterialApp));
          await tester.dragFrom(
            Offset(1, size.height / 2),
            Offset(size.width * .8, 0),
          );
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
      }

      await back();
      expect(router.state.uri.path, '/settings');
      await back();
      expect(router.state.uri.path, '/');
      expect(find.byKey(const Key('tab-1')).hitTestable(), findsOneWidget);
      unawaited(container.read(routerProvider).push('/edit/${character.id}'));
      await capture('editor');
      await tester.ensureVisible(find.byKey(const Key('choose-voice')));
      await capture('editor-scrolled');
      await tester.tap(find.byKey(const Key('choose-voice')));
      await capture('voices');
      await tester.tap(find.byKey(const Key('voice-close')));
      await tester.pumpAndSettle();
      coordinator.snapshot = CallSnapshot(
        phase: CallPhase.creating,
        character: character,
      );
      container.read(routerProvider).go('/call');
      await capture('connecting');
      coordinator.snapshot = const CallSnapshot();
      await coordinator.start(character, fake.credential, profile);
      expect(coordinator.snapshot.phase, CallPhase.joining);
      rtc.controller.add(
        const RtcUpdate(video: RemoteVideo('offline-room', 7)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('call-loading')), findsOneWidget);
      expect(find.byType(RtcVideoSurface), findsOneWidget);
      final videoState = tester.state(find.byType(RtcVideoSurface));
      rtc.controller.add(const RtcUpdate(firstFrame: true));
      await capture('call');
      expect(find.byKey(const Key('call-loading')), findsNothing);
      expect(tester.state(find.byType(RtcVideoSurface)), same(videoState));
      container.read(routerProvider).go('/');
      await tester.pumpAndSettle();
      unawaited(container.read(routerProvider).push('/call'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('end-call')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('character-image-${character.id}')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('character-image-input')), findsNothing);
      await coordinator.end();
      expect(coordinator.snapshot.phase, CallPhase.ended);
      await coordinator.start(character, fake.credential, profile);
      final backgroundCallId = coordinator.snapshot.callId;
      expect(
        coordinator.snapshot.phase,
        CallPhase.connected,
        reason:
            'Second simulated call: error=${coordinator.snapshot.error}; '
            'lifecycle=${binding.lifecycleState}; '
            'records=${(await local.watchCalls().first).map((row) => '${row.phase}:${row.endReason}').join(',')}',
      );
      container.read(routerProvider).go('/account');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-save')), findsOneWidget);
      expect(coordinator.snapshot.phase, CallPhase.connected);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // Paused applications do not schedule frames. Join the observer-triggered cleanup directly.
      await coordinator.end('app_background');
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(coordinator.snapshot.phase, CallPhase.ended);
      expect(
        (await local.watchCalls().first)
            .firstWhere((row) => row.id == backgroundCallId)
            .endReason,
        'app_background',
      );
      binding.reportData = {
        ...?binding.reportData,
        'offlineSmokeCompleted': true,
        'glassRenderers': qualities,
        'rendering': 'Easy public API: Impeller live backdrop or Skia Lite; pixels require visual review. Fake media, no platform video.',
        'media': 'SIMULATED; no real RTC or Vidu call',
        'microphoneStatus': status.name,
        'loadingDismissedAfterFrame': true,
        'videoRetainedAcrossLoading': true,
        'sqliteReopened': true,
        'hangupReturnedHome': true,
        'backNavigation': Platform.isIOS
            ? 'interactive-edge-swipe'
            : 'system-back',
        'backgroundEnded': true,
        'platform': Platform.operatingSystem,
        'os': Platform.operatingSystemVersion,
      };
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await coordinator.dispose();
      api.dispose();
      await db.close();
      await dir.delete(recursive: true);
    },
  );
}
