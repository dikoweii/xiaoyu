import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/app/runtime.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/presentation/controllers.dart';

import '../support/fixture.dart';

class _ProcessingController extends ScreenController {
  _ProcessingController(super.runtime);
  var submissions = 0;
  @override
  Future<Character> submitCharacter(Character value) async {
    submissions++;
    final updated = value.copyWith(
      avatarId: 'new-account-asset',
      assetStatus: submissions == 1 ? 'processing' : 'success',
    );
    await saveCharacter(updated);
    return updated;
  }
}

void main() {
  testWidgets(
    'submit shows processing and rechecks before leaving the editor',
    (tester) async {
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      final controller = _ProcessingController(fixture.app);
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
      final draft = await tester.runAsync(
        () => controller.createOfficialCharacter(officialCompanion),
      );
      final router = container.read(routerProvider);
      router.push<void>('/edit/${draft!.id}').ignore();
      await tester.pumpAndSettle();
      await tester.runAsync(() => controller.character(draft.id));
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('editor-save'));
      await tester.scrollUntilVisible(
        submit,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.runAsync(() => controller.character(draft.id));
      await tester.pumpAndSettle();
      expect(controller.submissions, 1);
      expect(router.state.uri.path, '/edit/${draft.id}');
      expect(find.textContaining('云端形象正在处理中'), findsOneWidget);
      expect(find.textContaining('请补全名称、人设、就绪形象'), findsNothing);
      await tester.tap(submit);
      await tester.runAsync(() => controller.character(draft.id));
      await tester.pumpAndSettle();
      expect(controller.submissions, 2);
      expect(router.state.uri.path, '/');
      expect(
        (await tester.runAsync(() => fixture.app.local.character(draft.id)))!
            .ready,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
