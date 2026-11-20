import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/app/runtime.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/presentation/controllers.dart';

import '../support/fixture.dart';

class _PhotoController extends ScreenController {
  _PhotoController(super.runtime, String path)
    : super(pickPhoto: () async => XFile(path));
  final images = <Character>[];
  final results = <StreamController<Character>>[];
  final active = <bool Function()>[];
  Character? submitted;
  @override
  Stream<Character> preparePhoto(
    Character image,
    bool Function() isActive, {
    String? editId,
  }) {
    images.add(image);
    active.add(isActive);
    final result = StreamController<Character>.broadcast();
    results.add(result);
    return result.stream;
  }

  @override
  Future<Character> submitCharacter(Character value, {String? editId}) async {
    submitted = value;
    await saveCharacter(value, editId: editId);
    return value;
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  for (final replace in [false, true]) {
    testWidgets(
      replace
          ? 'changing photos drops old preview results and exit stops polling'
          : 'selection starts preparation before submit while text and voice stay editable',
      (tester) async {
        final fixture = Fixture();
        await fixture.open();
        addTearDown(fixture.close);
        await fixture.app.credentials.save(
          'offline-only-key',
          remember: false,
          sameAccount: false,
        );
        final controller = _PhotoController(
          fixture.app,
          '${fixture.dir.path}/companion.png',
        );
        final container = ProviderContainer(
          overrides: [
            runtimeProvider.overrideWithValue(fixture.app),
            screenAwakeProvider.overrideWithValue((_) async {}),
            controllerProvider.overrideWithValue(controller),
            officialCatalogProvider.overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);
        tester.platformDispatcher.localesTestValue = [const Locale('zh')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const XiaoyuApp(),
          ),
        );
        await tester.pumpAndSettle();
        unawaited(container.read(routerProvider).push('/edit/new'));
        await _flush(tester);
        await tester.tap(find.byKey(const Key('upload-photo')));
        await _flush(tester);
        expect(controller.images, hasLength(1));
        expect(controller.images.single.name, isEmpty);
        expect(controller.submitted, isNull);
        expect(find.text('正在上传照片'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('character-name')),
          '上传时填写的名字',
        );
        await tester.enterText(
          find.byKey(const Key('persona-input')),
          '上传时填写的人设',
        );
        final first = controller.images.first;
        var selected = first;
        if (replace) {
          await tester.scrollUntilVisible(
            find.byKey(const Key('upload-photo')),
            -200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(const Key('upload-photo')));
          await _flush(tester);
          expect(controller.images, hasLength(2));
          selected = controller.images.last;
          expect(selected.imagePath, isNot(first.imagePath));
          expect(controller.active.first(), isFalse);
          controller.results.first.add(
            first.copyWith(avatarId: 'stale-a', assetStatus: 'success'),
          );
          await tester.pump();
          expect(find.text('形象已就绪'), findsNothing);
        } else {
          final chooseVoice = find.byKey(const Key('choose-voice'));
          await tester.scrollUntilVisible(
            chooseVoice,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(chooseVoice);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('voice-select-Tina')));
          await tester.pumpAndSettle();
        }
        controller.results.last.add(
          selected.copyWith(
            avatarId: 'current-asset',
            credentialId: fixture.app.credentials.currentId,
            assetStatus: 'success',
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(const Key('photo-preparation-status')),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('形象已就绪'), findsOneWidget);
        final submit = find.byKey(const Key('editor-save'));
        await tester.scrollUntilVisible(
          submit,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(submit);
        await _flush(tester);
        await tester.pumpAndSettle();
        expect(controller.submitted!.avatarId, 'current-asset');
        expect(controller.submitted!.name, '上传时填写的名字');
        expect(controller.submitted!.persona, '上传时填写的人设');
        expect(controller.submitted!.imagePath, selected.imagePath);
        expect(controller.submitted!.voice, replace ? 'Serena' : 'Tina');
        expect(controller.active.last(), isFalse);
        await tester.pumpWidget(const SizedBox());
        for (final result in controller.results) {
          await result.close();
        }
      },
    );
  }
}
