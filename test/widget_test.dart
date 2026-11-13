import 'dart:io';

import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/app/runtime.dart';
import 'package:xiaoyu/data/local/database.dart';
import 'package:xiaoyu/data/local/repositories.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';

void main() {
  test(
    'system locale respects language order and maps Chinese to simplified',
    () {
      expect(
        resolveLocale([
          const Locale('ja'),
          const Locale('zh', 'TW'),
          const Locale('en'),
        ]),
        const Locale('zh'),
      );
      expect(
        resolveLocale([const Locale('en', 'GB'), const Locale('zh')]),
        const Locale('en'),
      );
      expect(resolveLocale([const Locale('fr')]), const Locale('en'));
    },
  );
  for (final locale in ['en', 'zh']) {
    testWidgets(
      'device language changes preserve the app coordinator ($locale)',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final local = LocalRepository(db, Directory.systemTemp);
        // An old manual choice must no longer override device language.
        await local.setSetting('locale', locale == 'en' ? 'zh' : 'en');
        tester.platformDispatcher.localesTestValue = [Locale(locale)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final runtime = AppRuntime(
          local,
          CredentialRepository(local),
          ViduApi(),
          'profile',
        );
        final container = ProviderContainer(
          overrides: [
            runtimeProvider.overrideWithValue(runtime),
            screenAwakeProvider.overrideWithValue((_) async {}),
            officialCatalogProvider.overrideWith((ref) async => []),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await runtime.calls.dispose();
          runtime.api.dispose();
          await db.close();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const XiaoyuApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tab-0')).hitTestable(), findsOneWidget);
        expect(find.byKey(const Key('tab-1')).hitTestable(), findsOneWidget);
        expect(
          tester
              .widget<Semantics>(find.byKey(const Key('tab-accessibility-0')))
              .properties
              .label,
          locale == 'en' ? 'Home' : '首页',
        );
        final coordinator = container.read(runtimeProvider).calls;
        final next = locale == 'en' ? 'zh' : 'en';
        tester.platformDispatcher.localesTestValue = [Locale(next)];
        await tester.pumpAndSettle();
        expect(
          identical(container.read(runtimeProvider).calls, coordinator),
          isTrue,
        );
        expect(coordinator.snapshot.active, isFalse);
        expect(
          tester
              .widget<Semantics>(find.byKey(const Key('tab-accessibility-0')))
              .properties
              .label,
          next == 'en' ? 'Home' : '首页',
        );
        expect(find.byKey(const Key('tab-0')).hitTestable(), findsOneWidget);
        expect(find.byKey(const Key('tab-1')).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
