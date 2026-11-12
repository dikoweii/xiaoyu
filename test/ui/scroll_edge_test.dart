import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/ui/core/design.dart';
import 'package:xiaoyu/ui/core/widgets.dart';

import '../support/fixture.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Scroll Edge keeps full viewport and usable actions $platform $scale',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          tester.view.padding = const FakeViewPadding(top: 48, bottom: 24);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(() {
            debugDefaultTargetPlatformOverride = null;
            tester.view.resetDevicePixelRatio();
            tester.view.resetPhysicalSize();
            tester.view.resetPadding();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final fixture = Fixture();
          await fixture.open();
          addTearDown(fixture.close);
          var actions = 0;
          await fixture.pump(
            tester,
            page: AppPage(
              title: '页面标题',
              actions: [
                IconButton(
                  key: const Key('header-action'),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  tooltip: '保存',
                  onPressed: () => actions++,
                  icon: const Icon(Icons.check),
                ),
              ],
              body: PageBody(
                children: [
                  for (var i = 0; i < 20; i++)
                    SizedBox(height: 80, child: Text('内容 $i')),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();
          final edge = find.byType(LiquidGlassScrollEdge);
          final title = find.text('页面标题');
          final action = find.byKey(const Key('header-action'));
          final headerPosition = tester.getTopLeft(title);
          expect(find.byType(LiquidGlassAppBar), findsNothing);
          expect(
            tester.widget<LiquidGlassScrollEdge>(edge).blur,
            greaterThan(0),
          );
          expect(
            tester.getRect(find.byType(ListView)),
            const Rect.fromLTWH(0, 0, 320, 568),
          );
          expect(
            tester.getTopLeft(find.text('内容 0')).dy,
            greaterThan(tester.getBottomLeft(title).dy),
          );
          expect(tester.getTopLeft(action).dy, greaterThanOrEqualTo(48));
          expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
          await tester.tap(action);
          expect(actions, 1);
          // The feathered tail must let vertical gestures reach the list.
          final tail = tester.getBottomLeft(edge) + const Offset(160, -8);
          await tester.dragFrom(tail, const Offset(0, -100));
          await tester.pumpAndSettle();
          expect(
            tester.getTopLeft(find.text('内容 0')).dy,
            lessThan(headerPosition.dy),
          );
          expect(tester.getTopLeft(title), headerPosition);
          await tester.tap(action);
          expect(actions, 2);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }
  }
}
