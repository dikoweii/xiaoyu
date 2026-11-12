import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/ui/core/design.dart';
import 'package:xiaoyu/ui/core/widgets.dart';
import 'package:xiaoyu/ui/core/portrait_tile.dart';

import '../support/fixture.dart';

void main() {
  testWidgets(
    'many characters scroll horizontally without extending the section',
    (tester) async {
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      for (var i = 0; i < 30; i++) {
        await fixture.app.local.saveCharacter(
          companion.copyWith(id: 'extra-$i', name: '角色 $i'),
        );
      }
      await fixture.pump(tester);
      final carousel = find.byKey(
        const PageStorageKey('my-characters-carousel'),
      );
      expect(
        tester.widget<ListView>(carousel).scrollDirection,
        Axis.horizontal,
      );
      final height = tester.getSize(carousel).height;
      final heading = tester.getTopLeft(find.text('推荐数字人'));
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: carousel, matching: find.byType(Scrollable)),
      );
      await tester.drag(carousel, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(0));
      expect(tester.getSize(carousel).height, height);
      expect(tester.getTopLeft(find.text('推荐数字人')), heading);
      expect(find.byType(PortraitTile).evaluate().length, lessThan(31));
      expect(find.text('新增数字人'), findsNothing);
      expect(find.byKey(const Key('create-character')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('portrait owns chat; bare dots open only text actions', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester);
    final portrait = find.byKey(Key('character-image-${companion.id}'));
    final image = tester.widget<Image>(
      find.descendant(of: portrait, matching: find.byType(Image)),
    );
    expect(image.fit, BoxFit.contain);
    final frame = find.descendant(
      of: portrait,
      matching: find.byKey(const Key('portrait-tile-image')),
    );
    final imageRect = tester.getRect(frame);
    expect(imageRect.width / imageRect.height, closeTo(480 / 720, .001));
    expect(
      tester.widget<ClipRRect>(frame).borderRadius,
      BorderRadius.circular(24),
    );
    expect(
      find.ancestor(of: portrait, matching: find.byType(AppSurface)),
      findsNothing,
    );
    final caption = tester.getRect(find.text(companion.summary));
    expect(imageRect.contains(caption.topLeft), isTrue);
    expect(imageRect.contains(caption.bottomRight), isTrue);
    expect(find.byKey(Key('chat-${companion.id}')), findsNothing);
    final dots = find.byKey(const Key('character-menu'));
    expect(tester.getTopRight(dots), imageRect.topRight + const Offset(-4, 4));
    expect(
      find.ancestor(of: dots, matching: find.byType(LiquidGlassMorph)),
      findsNothing,
    );
    await tester.tap(dots);
    await tester.pumpAndSettle();
    final panel = find.byKey(const Key('character-menu-panel'));
    expect(
      find.descendant(of: panel, matching: find.byType(Icon)),
      findsNothing,
    );
    expect(
      find.descendant(of: panel, matching: find.byType(Divider)),
      findsNothing,
    );
    final label = tester.widget<Text>(find.text('删除'));
    expect(
      DefaultTextStyle.of(tester.element(find.byWidget(label))).style.color,
      Colors.redAccent,
    );
    expect(fixture.container.read(routerProvider).state.uri.path, '/');
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    await tester.tap(portrait);
    await tester.pumpAndSettle();
    expect(fixture.container.read(routerProvider).state.uri.path, '/account');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'recommended image opens an editor with persisted metadata prefilled',
    (tester) async {
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      await fixture.pump(tester);
      final card = find.byKey(const Key('official-offline-role-1'));
      await tester.scrollUntilVisible(
        card,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('一起分享生活的小事。'), findsOneWidget);
      expect(find.text('Vidu 官方形象'), findsNothing);
      expect(find.text('查看更多'), findsNothing);
      expect(
        find.descendant(of: card, matching: find.byType(AppIconButton)),
        findsNothing,
      );
      expect(
        tester
            .widget<Image>(
              find.descendant(of: card, matching: find.byType(Image)),
            )
            .fit,
        BoxFit.contain,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      final draft = (await tester.runAsync(
        () => fixture.app.local.watchCharacters().first,
      ))!.singleWhere((c) => c.officialRoleId == 'offline-role-1');
      expect(
        fixture.container.read(routerProvider).state.uri.path,
        '/edit/${draft.id}',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('character-name')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '离线角色 A',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('persona-input')))
            .controller!
            .text,
        contains('耐心倾听'),
      );
      expect(draft.summary, '一起分享生活的小事。');
      expect(draft.sourceImageUrl, 'https://example.invalid/profile.png');
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      'tab uses fixed bottom gap independent of safe area $platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(402, 874);
        tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
          tester.view.resetPadding();
        });
        final fixture = Fixture();
        await fixture.open();
        addTearDown(fixture.close);
        await fixture.pump(tester);
        expect(
          tester.getBottomLeft(find.byKey(const Key('home-tabs'))).dy,
          848,
        );
        await tester.tap(find.byKey(const Key('tab-1')));
        await tester.pumpAndSettle();
        expect(find.text('本地个人资料').hitTestable(), findsOneWidget);
        expect(find.byType(Divider), findsNothing);
        tester.view.padding = const FakeViewPadding(top: 59);
        await tester.pumpAndSettle();
        expect(
          fixture.container.read(routerProvider).state.uri.path,
          '/',
          reason: 'Changing the safe area must preserve the home route',
        );
        expect(
          tester.getBottomLeft(find.byKey(const Key('home-tabs'))).dy,
          848,
        );
        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
