import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/app/runtime.dart';
import 'package:xiaoyu/presentation/controllers.dart';

import '../support/fixture.dart';

Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

void main() {
  Future<(Fixture, ProviderContainer)> open(
    WidgetTester tester, {
    bool existing = false,
    bool photo = false,
    String locale = 'zh',
  }) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    final controller = ScreenController(
      fixture.app,
      pickPhoto: () async =>
          photo ? XFile('${fixture.dir.path}/companion.png') : null,
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
    tester.platformDispatcher.localesTestValue = [Locale(locale)];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const XiaoyuApp()),
    );
    await tester.pumpAndSettle();
    unawaited(
      container
          .read(routerProvider)
          .push('/edit/${existing ? companion.id : 'new'}'),
    );
    await flush(tester);
    return (fixture, container);
  }

  testWidgets('untouched form and canceled photo picker leave no draft', (
    tester,
  ) async {
    final (fixture, container) = await open(tester);
    await tester.tap(find.byKey(const Key('upload-photo')));
    await flush(tester);
    await tester.binding.handlePopRoute();
    await flush(tester);
    expect(container.read(routerProvider).state.uri.path, '/');
    expect(
      await tester.runAsync(() => fixture.app.local.watchCharacters().first),
      hasLength(1),
    );
    expect(find.byKey(const Key('edit-save')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final action in ['edit-discard', 'edit-save', 'edit-continue']) {
    testWidgets('modified form supports $action without implicit publication', (
      tester,
    ) async {
      final (fixture, container) = await open(tester);
      await tester.enterText(
        find.byKey(const Key('character-name')),
        '明确保存的名字',
      );
      await tester.pump();
      await tester.binding.handlePopRoute();
      await flush(tester);
      expect(find.text('保存当前修改？'), findsOneWidget);
      expect(
        await tester.runAsync(() => fixture.app.local.watchCharacters().first),
        hasLength(1),
      );
      await tester.tap(find.byKey(Key(action)));
      await flush(tester);
      if (action == 'edit-continue') {
        expect(container.read(routerProvider).state.uri.path, '/edit/new');
        expect(find.text('明确保存的名字'), findsOneWidget);
        await tester.pump();
        await tester.binding.handlePopRoute();
        await flush(tester);
        await tester.tap(find.byKey(const Key('edit-discard')));
        await flush(tester);
      }
      expect(container.read(routerProvider).state.uri.path, '/');
      final roles = await tester.runAsync(
        () => fixture.app.local.watchCharacters().first,
      );
      expect(roles, hasLength(action == 'edit-save' ? 2 : 1));
      if (action == 'edit-save') {
        expect(
          roles!.where((c) => c.name == '明确保存的名字').single.persona,
          isEmpty,
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'reverting text to its initial value exits without confirmation',
    (tester) async {
      final (fixture, container) = await open(tester);
      await tester.enterText(find.byKey(const Key('character-name')), '临时');
      await tester.enterText(find.byKey(const Key('character-name')), '');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await flush(tester);
      expect(container.read(routerProvider).state.uri.path, '/');
      expect(
        await tester.runAsync(() => fixture.app.local.watchCharacters().first),
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final existing in [false, true]) {
    testWidgets(
      'photo-only change $existing prompts and discard preserves original',
      (tester) async {
        final (fixture, container) = await open(
          tester,
          existing: existing,
          photo: true,
        );
        await tester.tap(find.byKey(const Key('upload-photo')));
        await flush(tester);
        final before = await tester.runAsync(
          () => fixture.app.local.watchCharacters().first,
        );
        expect(before, hasLength(1));
        expect(before!.single.imagePath, companion.imagePath);
        await tester.pump();
        await tester.binding.handlePopRoute();
        await flush(tester);
        expect(find.byKey(const Key('edit-discard')), findsOneWidget);
        await tester.tap(find.byKey(const Key('edit-discard')));
        await flush(tester);
        expect(container.read(routerProvider).state.uri.path, '/');
        final after = await tester.runAsync(
          () => fixture.app.local.watchCharacters().first,
        );
        expect(after!.single.toJson(), companion.toJson());
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final locale in ['zh', 'en']) {
    testWidgets(
      'unsaved actions fit small screens at large text size $locale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await open(tester, locale: locale);
        await tester.enterText(
          find.byKey(const Key('character-name')),
          'Draft',
        );
        await tester.pump();
        await tester.binding.handlePopRoute();
        await flush(tester);
        for (final action in ['edit-save', 'edit-discard', 'edit-continue']) {
          expect(find.byKey(Key(action)).hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('edit-discard')));
        await flush(tester);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
