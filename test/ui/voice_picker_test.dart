import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/domain/voice_catalog.dart';
import 'package:xiaoyu/ui/voice_picker.dart';
import 'package:xiaoyu/domain/voice_preview.dart';

import '../support/fixture.dart';
import '../support/preview_audio.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('voice-list')),
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 100,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'preview loading can be cancelled; failures retry and background stops',
    (tester) async {
      final audio = FakePreviewAudio();
      final fixture = Fixture(previewAudio: audio);
      await fixture.open();
      addTearDown(fixture.close);
      await fixture.pump(
        tester,
        page: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => chooseVoice(context, 'Serena'),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('voice-provider-doubao')));
      await tester.pumpAndSettle();
      final button = find.byKey(
        const Key('voice-preview-zh_female_vv_uranus_bigtts'),
      );
      audio.pending = Completer<void>();
      await tester.tap(button);
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(button);
      audio.pending!.complete();
      audio.pending = null;
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      audio.fail = true;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('试听加载失败，请稍后重试'), findsOneWidget);
      audio.fail = false;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(audio.disposed, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'avatar preview toggles, completes and stops on tab, selection and dismissal',
    (tester) async {
      final audio = FakePreviewAudio();
      final fixture = Fixture(previewAudio: audio);
      await fixture.open();
      addTearDown(fixture.close);
      VoiceSelection? result;
      await fixture.pump(
        tester,
        page: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await chooseVoice(context, 'Serena'),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('voice-preview-Serena')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('voice-preview-Serena')));
      await tester.pumpAndSettle();
      final serena = findVoice(VoiceProvider.qwenOmni, 'Serena')!;
      expect(audio.plays.single, (serena.id, serena.trialUrl));
      expect(serena.avatarUrl, isEmpty);
      expect(find.byType(Image), findsNothing);
      expect(result, isNull);
      Future<void> openDoubao() async {
        await tester.tap(find.byKey(const Key('voice-provider-doubao')));
        await tester.pumpAndSettle();
      }

      const id = 'zh_female_vv_uranus_bigtts';
      final button = find.byKey(const Key('voice-preview-$id'));
      await openDoubao();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(audio.plays.last.$1, id);
      expect(result, isNull);
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      await tester.tap(button);
      await tester.pumpAndSettle();
      audio.controller.add(const PreviewAudioEvent(id));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('voice-provider-qwen_omni')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      await openDoubao();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('voice-select-$id')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(result!.id, id);
      expect(find.byType(VoicePicker), findsNothing);
      await fixture.container.pump();
      expect(audio.disposed, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('compact provider list returns voice and provider atomically', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    VoiceSelection? result;
    await fixture.pump(
      tester,
      page: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await chooseVoice(context, 'Serena');
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voice-provider-doubao')));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('苏瑶 Serena'), findsNothing);
    final select = find.byKey(
      const Key('voice-select-zh_female_vv_uranus_bigtts'),
    );
    await reveal(tester, select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    expect(result!.provider, VoiceProvider.doubao);
    expect(result!.id, 'zh_female_vv_uranus_bigtts');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'cancel preserves an unlisted saved voice without changing the preference',
    (tester) async {
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      VoiceSelection? result;
      await fixture.pump(
        tester,
        page: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await chooseVoice(context, 'Cherry');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('voice-saved-not-listed')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('simple list hides metadata and reaches the full catalog', (
    tester,
  ) async {
    final fixture = Fixture(locale: 'en');
    await fixture.open();
    addTearDown(fixture.close);
    VoiceSelection? result;
    await fixture.pump(
      tester,
      page: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await chooseVoice(context, 'Serena');
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('苏瑶 Serena'), findsOneWidget);
    expect(find.text('Serena'), findsNothing);
    final serena = findVoice(VoiceProvider.qwenOmni, 'Serena')!;
    expect(find.text(serena.description), findsNothing);
    expect(find.text(serena.languages), findsNothing);
    final last = officialVoices.lastWhere(
      (v) => v.provider == VoiceProvider.qwenOmni,
    );
    final select = find.byKey(Key('voice-select-${last.id}'));
    await reveal(tester, select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    expect(result!.id, last.id);
    expect(result!.provider, last.provider);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
