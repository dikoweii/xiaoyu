import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/ui/call_history.dart';

import '../support/fixture.dart';

void main() {
  testWidgets(
    'history preview and full list share narrow gutters and open details',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final fixture = Fixture(historyCount: 30);
      await fixture.open();
      addTearDown(fixture.close);
      await fixture.pump(tester);
      await tester.tap(find.byKey(const Key('tab-1')));
      await tester.pumpAndSettle();
      expect(find.byType(CallTile), findsNWidgets(4));
      final first = find.byKey(const ValueKey('history-offline-history'));
      expect(tester.getTopLeft(first).dx, 16);
      expect(tester.getSize(first).width, 370);
      final all = find.byKey(const Key('view-all-history'));
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(fixture.container.read(routerProvider).state.uri.path, '/history');
      final list = find.byKey(const Key('history-list'));
      expect(list, findsOneWidget);
      expect(tester.getTopLeft(first).dx, 16);
      expect(tester.getSize(first).width, 370);
      final last = find.byKey(const ValueKey('history-offline-history-29'));
      expect(
        tester.getTopLeft(first).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byType(NavigationToolbar)).dy,
        ),
      );
      expect(last, findsNothing, reason: 'Offscreen records must build lazily');
      await tester.scrollUntilVisible(
        last,
        350,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      await Scrollable.ensureVisible(tester.element(last), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(
        fixture.container.read(routerProvider).state.uri.path,
        '/history/offline-history-29',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('empty history keeps view-all reachable without fake records', (
    tester,
  ) async {
    final fixture = Fixture(empty: true);
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const Key('tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('还没有通话记录'), findsOneWidget);
    expect(find.byType(CallTile), findsNothing);
    await tester.tap(find.byKey(const Key('view-all-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-list')), findsOneWidget);
    expect(find.text('还没有通话记录'), findsOneWidget);
    expect(find.byType(CallTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
