import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/ui/character_menu.dart';
import 'package:xiaoyu/ui/core/design.dart';

import '../support/fixture.dart';

void main() {
  testWidgets('reduced motion and repeated taps keep one dismissible menu', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    final selected = <CharacterMenuAction>[];
    await fixture.pump(
      tester,
      page: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: CharacterMenu(onSelected: selected.add),
        ),
      ),
    );
    final button = tester.widget<IconButton>(
      find.byKey(const Key('character-menu')),
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('character-menu-panel')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(
      find.byKey(const Key('character-menu')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final locale in ['zh', 'en']) {
      for (final corner in [Alignment.topLeft, Alignment.bottomRight]) {
        testWidgets('character morph menu $platform $locale $corner', (
          tester,
        ) async {
          debugDefaultTargetPlatformOverride = platform;
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          tester.view.padding = const FakeViewPadding(top: 48, bottom: 24);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(() {
            debugDefaultTargetPlatformOverride = null;
            tester.view.resetDevicePixelRatio();
            tester.view.resetPhysicalSize();
            tester.view.resetPadding();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final fixture = Fixture(locale: locale);
          await fixture.open();
          addTearDown(fixture.close);
          final selected = <CharacterMenuAction>[];
          var outsideTaps = 0;
          await fixture.pump(
            tester,
            page: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => outsideTaps++,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: corner,
                        child: CharacterMenu(onSelected: selected.add),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          Future<void> open() async {
            final trigger = find.byKey(const Key('character-menu'));
            expect(tester.getSize(trigger), const Size(48, 48));
            await tester.tap(trigger);
            await tester.pumpAndSettle();
            expect(find.byType(LiquidGlassMorph), findsWidgets);
            final rect = tester.getRect(
              find.byKey(const Key('character-menu-panel')),
            );
            expect(rect.left, greaterThanOrEqualTo(12));
            expect(rect.right, lessThanOrEqualTo(308));
            expect(rect.top, greaterThanOrEqualTo(48));
            expect(rect.bottom, lessThanOrEqualTo(544));
            final longestLabel = tester
                .widgetList<Text>(
                  find.descendant(
                    of: find.byKey(const Key('character-menu-panel')),
                    matching: find.byType(Text),
                  ),
                )
                .map((text) => tester.getSize(find.byWidget(text)).width)
                .reduce((a, b) => a > b ? a : b);
            expect(
              rect.width,
              inInclusiveRange(longestLabel + 24, longestLabel + 48),
            );
            for (final action in ['edit', 'delete']) {
              final target = find.byKey(Key('menu-$action')).hitTestable();
              expect(target, findsOneWidget);
              expect(
                tester.getSize(target).shortestSide,
                greaterThanOrEqualTo(48),
              );
              final handle = tester.ensureSemantics();
              expect(
                tester.getSemantics(target).getSemanticsData().label,
                isNotEmpty,
              );
              handle.dispose();
            }
            expect(tester.takeException(), isNull);
          }

          await open();
          await tester.tapAt(const Offset(160, 300));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('character-menu-panel')), findsNothing);
          expect(outsideTaps, 0);
          expect(selected, isEmpty);
          await open();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('character-menu-panel')), findsNothing);
          await open();
          await tester.tap(find.byKey(const Key('menu-edit')));
          await tester.pumpAndSettle();
          expect(selected, [CharacterMenuAction.edit]);
          await open();
          await tester.tap(find.byKey(const Key('menu-delete')));
          await tester.pumpAndSettle();
          expect(selected, [
            CharacterMenuAction.edit,
            CharacterMenuAction.delete,
          ]);
          await tester.pumpWidget(const SizedBox());
          debugDefaultTargetPlatformOverride = null;
        });
      }
    }
  }
}
