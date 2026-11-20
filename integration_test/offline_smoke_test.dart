import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/app/bootstrap.dart';
import 'package:xiaoyu/ui/core/design.dart';
import 'package:xiaoyu/ui/call_history.dart' show presenceAnimationProvider;
import 'package:xiaoyu/app/runtime.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/data/local/database.dart';
import 'package:xiaoyu/data/local/repositories.dart';
import 'package:xiaoyu/data/local/call_store.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/data/services/voice_preview_audio.dart';
import 'package:xiaoyu/presentation/voice_preview.dart';
import 'package:xiaoyu/presentation/controllers.dart'
    show ScreenController, controllerProvider;
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/domain/voice_catalog.dart';
import 'package:xiaoyu/domain/call_ports.dart';
import 'package:xiaoyu/ui/integrations/rtc_video_surface.dart';

import '../test/support/offline.dart';
import '../test/support/preview_audio.dart';
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
      // A local generated tone checks the real native decoder with no network.
      const rate = 16000;
      const samples = rate ~/ 4;
      final wav = ByteData(44 + samples * 2);
      void ascii(int offset, String value) {
        for (var i = 0; i < value.length; i++) {
          wav.setUint8(offset + i, value.codeUnitAt(i));
        }
      }

      ascii(0, 'RIFF');
      wav.setUint32(4, wav.lengthInBytes - 8, Endian.little);
      ascii(8, 'WAVEfmt ');
      wav.setUint32(16, 16, Endian.little);
      wav.setUint16(20, 1, Endian.little);
      wav.setUint16(22, 1, Endian.little);
      wav.setUint32(24, rate, Endian.little);
      wav.setUint32(28, rate * 2, Endian.little);
      wav.setUint16(32, 2, Endian.little);
      wav.setUint16(34, 16, Endian.little);
      ascii(36, 'data');
      wav.setUint32(40, samples * 2, Endian.little);
      for (var i = 0; i < samples; i++) {
        wav.setInt16(
          44 + i * 2,
          (math.sin(i * 440 * 2 * math.pi / rate) * 1000).round(),
          Endian.little,
        );
      }
      final tone = File('${dir.path}/preview.wav');
      await tone.writeAsBytes(wav.buffer.asUint8List());
      final nativePreview = VoicePreviewAudio();
      final completed = nativePreview.events.first.timeout(
        const Duration(seconds: 15),
      );
      await nativePreview.play('offline-tone', tone.uri.toString());
      final nativeResult = await completed;
      expect(nativeResult.failed, isFalse);
      expect(nativeResult.id, 'offline-tone');
      await nativePreview.dispose();
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
      var avatarUploads = 0;
      var avatarQueries = 0;
      Object? uploadedImageUri;
      final avatarResponse = Completer<Map<String, Object?>>();
      final avatarStarted = Completer<void>();
      final api = ViduApi(
        client: offlineDio((request) async {
          if (Uri.parse(request.path).path == '/live/v1/avatars' &&
              request.method == 'POST') {
            avatarUploads++;
            final data = request.data is String
                ? jsonDecode(request.data as String)
                : request.data;
            // Assert from the test flow: expect() here can trip Flutter's
            // async guard during pump and be wrapped by Dio as a network error.
            uploadedImageUri = (data as Map)['image_uri'];
            avatarStarted.complete();
            return jsonBody(await avatarResponse.future);
          }
          if (Uri.parse(request.path).path ==
                  '/live/v1/avatars/offline-prepared-avatar' &&
              request.method == 'GET') {
            avatarQueries++;
            return jsonBody({
              'id': 'offline-prepared-avatar',
              'status': 'success',
            });
          }
          throw StateError('Unexpected offline HTTP route');
        }),
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
      addTearDown(WakelockPlus.disable);
      final previewAudio = FakePreviewAudio();
      final container = ProviderContainer(
        overrides: [
          previewAudioFactoryProvider.overrideWithValue(() => previewAudio),
          voiceAvatarProvider.overrideWithValue(
            (_) => FileImage(File('${dir.path}/portrait.png')),
          ),
          runtimeProvider.overrideWithValue(app),
          controllerProvider.overrideWithValue(
            ScreenController(
              app,
              pickPhoto: () async => XFile('${dir.path}/portrait.png'),
            ),
          ),
          presenceAnimationProvider.overrideWithValue(false),
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
        // Connecting deliberately keeps painting. Waiting for it to settle
        // would run until the real preparation deadline, ending the test call.
        if (coordinator.snapshot.active && !coordinator.snapshot.interactive) {
          await tester.pump();
          for (
            var frame = 0;
            frame < 20 &&
                find.byKey(const Key('call-loading')).evaluate().isEmpty;
            frame++
          ) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.byKey(const Key('call-loading')), findsOneWidget);
          // Advance the route transition after its first laid out frame.
          await tester.pump(const Duration(milliseconds: 500));
        } else {
          await tester.pumpAndSettle();
        }
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
      expect(
        (await local.watchCharacters().first).where(
          (c) => c.officialRoleId == 'offline-role-0',
        ),
        isEmpty,
      );
      expect(find.text('Offline 0'), findsOneWidget);
      expect(find.text('Offline companion prompt 0'), findsOneWidget);
      expect(
        container.read(routerProvider).state.uri.path,
        startsWith('/edit/'),
      );
      await capture('official-prefill');
      container.read(routerProvider).pop();
      await tester.pumpAndSettle();
      // Carousel interaction needs two explicitly saved roles; opening a
      // recommendation now leaves the home list unchanged.
      await local.saveCharacter(
        character.copyWith(id: 'offline-second', name: 'Offline extra'),
      );
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
      await app.credentials.save(
        'offline-photo-key',
        remember: false,
        sameAccount: false,
      );
      final originalRoleCount = (await local.watchCharacters().first).length;
      unawaited(router.push('/edit/new'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('page-back')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      expect((await local.watchCharacters().first).length, originalRoleCount);
      unawaited(router.push('/edit/new'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('character-name')), '尚未保存');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('page-back')));
      await tester.pumpAndSettle();
      await capture('unsaved-character');
      await tester.tap(find.byKey(const Key('edit-continue')));
      await tester.pumpAndSettle();
      expect(find.text('尚未保存'), findsOneWidget);
      await tester.tap(find.byKey(const Key('page-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-discard')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      expect((await local.watchCharacters().first).length, originalRoleCount);
      unawaited(router.push('/edit/new'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('upload-photo')));
      await tester.pumpAndSettle();
      // DB/file completion schedules another frame before the provider starts.
      // Keep driving frames while waiting, just as the visible app does.
      for (var frame = 0; frame < 100 && !avatarStarted.isCompleted; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final photoStates = (await local.watchCharacters().first)
          .map((c) => '${c.assetStatus}:image=${c.imagePath.isNotEmpty}')
          .join(',');
      expect(
        avatarStarted.isCompleted,
        isTrue,
        reason: 'Photo state=$photoStates',
      );
      expect(avatarUploads, 1);
      expect(uploadedImageUri, startsWith('data:image/png;base64,'));
      await capture('photo-uploading');
      await tester.enterText(find.byKey(const Key('character-name')), '提前准备形象');
      await tester.enterText(
        find.byKey(const Key('persona-input')),
        '在图片上传时填写的人设',
      );
      avatarResponse.complete({
        'id': 'offline-prepared-avatar',
        'status': 'processing',
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('photo-preparation-status')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      for (
        var attempt = 0;
        attempt < 20 && find.text('形象已就绪').evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('形象已就绪'), findsOneWidget);
      await capture('photo-ready');
      expect(
        (await app.local.watchCharacters().first).where(
          (c) => c.avatarId == 'offline-prepared-avatar',
        ),
        isEmpty,
        reason: 'Preparation must not publish an unsaved role',
      );
      final submitPhoto = find.byKey(const Key('editor-save'));
      await tester.scrollUntilVisible(
        submitPhoto,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitPhoto);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      final preparedPhoto = (await local.watchCharacters().first).singleWhere(
        (c) => c.avatarId == 'offline-prepared-avatar',
      );
      expect(preparedPhoto.name, '提前准备形象');
      expect(preparedPhoto.persona, '在图片上传时填写的人设');
      expect(
        (buildSession(preparedPhoto, profile)['avatar'] as Map)['id'],
        'offline-prepared-avatar',
      );
      expect(avatarUploads, 1);
      expect(live.creates, 0);
      // Reopen a saved processing snapshot after the cloud has already finished.
      // Home must reconcile it without another submit, upload or live creation.
      final beforeHomeQuery = avatarQueries;
      await local.saveCharacter(
        preparedPhoto.copyWith(assetStatus: 'processing'),
      );
      for (var attempt = 0; attempt < 40; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if ((await local.character(preparedPhoto.id))!.ready) break;
      }
      expect((await local.character(preparedPhoto.id))!.ready, isTrue);
      expect(avatarQueries, greaterThan(beforeHomeQuery));
      expect(avatarUploads, 1);
      expect(live.creates, 0);
      await capture('avatar-sync-ready');
      unawaited(container.read(routerProvider).push('/edit/${character.id}'));
      await capture('editor');
      await tester.ensureVisible(find.byKey(const Key('choose-voice')));
      await capture('editor-scrolled');
      await tester.tap(find.byKey(const Key('choose-voice')));
      await capture('voices');
      expect(find.byKey(const Key('voice-close')), findsNothing);
      await tester.tap(find.byKey(const Key('voice-preview-Serena')));
      await tester.pumpAndSettle();
      expect(previewAudio.plays.single, (
        'Serena',
        findVoice(VoiceProvider.qwenOmni, 'Serena')!.trialUrl,
      ));
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      await capture('voices-qwen-preview');
      await tester.tap(find.byKey(const Key('voice-provider-doubao')));
      await capture('voices-doubao');
      await tester.tap(
        find.byKey(const Key('voice-preview-zh_female_vv_uranus_bigtts')),
      );
      await tester.pumpAndSettle();
      expect(previewAudio.plays.last.$1, 'zh_female_vv_uranus_bigtts');
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      await capture('voices-doubao-preview');
      final select = find.byKey(
        const Key('voice-select-zh_female_vv_uranus_bigtts'),
      );
      await tester.scrollUntilVisible(
        select,
        160,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('voice-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(select);
      await tester.pumpAndSettle();
      expect(find.textContaining('Vivi 2.0'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('advanced-settings')));
      await tester.tap(find.byKey(const Key('advanced-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('draft-save')));
      await tester.tap(find.byKey(const Key('draft-save')));
      await tester.pumpAndSettle();
      final savedVoice = (await local.character(character.id))!;
      expect(savedVoice.voiceProvider, VoiceProvider.doubao);
      expect(savedVoice.voice, 'zh_female_vv_uranus_bigtts');
      expect(
        live.creates,
        0,
      ); // Choosing and saving a voice never creates a live.
      unawaited(router.push('/edit/${character.id}'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('choose-voice')));
      expect(find.textContaining('Vivi 2.0'), findsOneWidget);
      await capture('editor-voice-saved');
      await back();
      await tester.pumpAndSettle();
      await coordinator.start(character, fake.credential, profile);
      expect(coordinator.snapshot.phase, CallPhase.joining);
      container.read(routerProvider).go('/call');
      await capture('connecting');
      expect(await WakelockPlus.enabled, isTrue);
      rtc.controller.add(
        const RtcUpdate(video: RemoteVideo('offline-room', 7)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('call-loading')), findsOneWidget);
      expect(find.byType(RtcVideoSurface), findsOneWidget);
      final videoState = tester.state(find.byType(RtcVideoSurface));
      rtc.controller.add(const RtcUpdate(firstFrame: true));
      await capture('call');
      expect(await WakelockPlus.enabled, isTrue);
      expect(find.byKey(const Key('call-loading')), findsNothing);
      expect(tester.state(find.byType(RtcVideoSurface)), same(videoState));
      expect(find.byKey(const Key('call-menu')), findsNothing);
      expect(find.byKey(const Key('call-live-indicator')), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const Key('open-call-composer')));
      await capture('call-composer');
      await tester.enterText(
        find.byKey(const Key('chat-input')),
        'Offline hello',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(signal.sent.last, 102);
      await tester.tap(find.byKey(const Key('quick-action-heart')));
      await tester.pumpAndSettle();
      expect(signal.sent.last, 101);
      final sentBeforeCategory = signal.sent.length;
      await tester.ensureVisible(find.byKey(const Key('quick-category-food')));
      await tester.tap(find.byKey(const Key('quick-category-food')));
      await capture('call-food');
      expect(
        find.byKey(const Key('quick-action-watermelon')).hitTestable(),
        findsOneWidget,
      );
      expect(signal.sent.length, sentBeforeCategory);
      await tester.ensureVisible(
        find.byKey(const Key('quick-category-common')),
      );
      await tester.tap(find.byKey(const Key('quick-category-common')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('quick-action-heart')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('close-call-composer')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(tester.state(find.byType(RtcVideoSurface)), same(videoState));
      await tester.tap(find.byKey(const Key('toggle-playback')));
      await tester.pumpAndSettle();
      expect(rtc.playbackMuted, isTrue);
      expect(rtc.muted, isFalse);
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(find.byKey(const Key('toggle-playback')));
      await tester.pumpAndSettle();
      expect(rtc.playbackMuted, isFalse);
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
      await tester.pumpAndSettle();
      expect(await WakelockPlus.enabled, isFalse);
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
      expect(await WakelockPlus.enabled, isFalse);
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
        'photoPreparedBeforeSubmit': preparedPhoto.avatarId,
        'photoUploadCount': avatarUploads,
        'savedAvatarAutoUpdated': true,
        'voiceProviderSaved': savedVoice.voiceProvider.apiValue,
        'voiceSelectionSaved': savedVoice.voice,
        'nativePreviewCompleted': nativeResult.id,
        'doubaoPreviewMatched': previewAudio.plays.last.$1,
        'qwenPreviewMatched': previewAudio.plays.first.$1,
        'hangupReturnedHome': true,
        'backNavigation': Platform.isIOS
            ? 'interactive-edge-swipe'
            : 'system-back',
        'backgroundEnded': true,
        'screenAwakeDuringCall': true,
        'screenSleepRestored': true,
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
