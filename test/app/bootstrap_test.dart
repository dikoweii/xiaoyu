import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/bootstrap.dart';

void main() {
  testWidgets('shows artwork until initialization completes once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ready = Completer<Widget>();
    var starts = 0;
    await tester.pumpWidget(
      XiaoyuBootstrap(
        initialize: () {
          starts++;
          return ready.future;
        },
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final artwork = find.byKey(const Key('launch-artwork'));
    expect(tester.widget<Image>(artwork).fit, BoxFit.contain);
    expect(tester.getSize(artwork), const Size(320, 568));
    expect(starts, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(artwork, findsOneWidget);
    expect(starts, 1);
    ready.complete(const SizedBox(key: Key('ready')));
    await tester.pumpAndSettle();
    expect(artwork, findsNothing);
    expect(find.byKey(const Key('ready')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(402, 874),
  ]) {
    testWidgets('launch is only slightly larger and keeps text on $viewport', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ready = Completer<Widget>();
      await tester.pumpWidget(XiaoyuBootstrap(initialize: () => ready.future));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(
        find.byKey(const Key('launch-artwork')),
      );
      final size = tester.getSize(find.byKey(const Key('launch-artwork')));
      const sourceSize = Size(848, 1264);
      final fitted = applyBoxFit(image.fit!, sourceSize, size);
      final alignment = image.alignment.resolve(TextDirection.ltr);
      final source = alignment.inscribe(
        fitted.source,
        Offset.zero & sourceSize,
      );
      final destination = alignment.inscribe(
        fitted.destination,
        Offset.zero & size,
      );
      final transform = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byKey(const Key('launch-artwork')),
              matching: find.byType(Transform),
            )
            .first,
      );
      final zoom = transform.transform.entry(0, 0);
      expect(zoom, closeTo(1.06, .001));
      expect(image.fit, BoxFit.contain);
      // Bounds measured from the supplied poster, including every text line.
      const text = Rect.fromLTRB(225, 842, 625, 1080);
      expect(source.left, lessThan(text.left));
      expect(source.right, greaterThan(text.right));
      expect(source.top, lessThan(text.top));
      expect(source.bottom, greaterThan(text.bottom));
      Offset displayed(Offset point) {
        final fittedPoint =
            destination.topLeft +
            (point - source.topLeft) * (destination.width / source.width);
        return viewport.center(Offset.zero) +
            (fittedPoint - viewport.center(Offset.zero)) * zoom;
      }

      final screen = Offset.zero & viewport;
      expect(screen.contains(displayed(text.topLeft)), isTrue);
      expect(screen.contains(displayed(text.bottomRight)), isTrue);
      expect(destination.width * zoom, closeTo(viewport.width * 1.06, .01));
      expect(tester.takeException(), isNull);
      ready.complete(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'a failed startup offers explicit retry without exposing errors',
    (tester) async {
      var starts = 0;
      await tester.pumpWidget(
        XiaoyuBootstrap(
          initialize: () async {
            starts++;
            if (starts == 1) throw StateError('private diagnostic');
            return const SizedBox(key: Key('ready'));
          },
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(find.textContaining('private diagnostic'), findsNothing);
      expect(find.byType(TextButton), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(starts, 2);
      expect(find.byKey(const Key('ready')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
