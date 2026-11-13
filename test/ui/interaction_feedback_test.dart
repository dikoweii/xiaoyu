import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/ui/core/controls.dart';
import 'package:xiaoyu/ui/core/portrait_tile.dart';

import '../support/fixture.dart';

void main() {
  final controls = <String, Widget Function(VoidCallback)>{
    'text button': (tap) =>
        AppButton(plain: true, onPressed: tap, child: const Text('Action')),
    'filled button': (tap) =>
        AppButton(primary: true, onPressed: tap, child: const Text('Action')),
    'glass button': (tap) =>
        AppButton(onPressed: tap, child: const Text('Action')),
    'delete text button': (tap) => AppButton(
      plain: true,
      destructive: true,
      onPressed: tap,
      child: const Text('Delete'),
    ),
    'delete glass button': (tap) => AppButton(
      destructive: true,
      onPressed: tap,
      child: const Text('Delete'),
    ),
    'glass icon': (tap) => AppIconButton(
      label: 'Action',
      icon: const Icon(Icons.add),
      onPressed: tap,
    ),
    'icon button': (tap) =>
        IconButton(onPressed: tap, icon: const Icon(Icons.add)),
    'list tile': (tap) => ListTile(title: const Text('Action'), onTap: tap),
    'portrait': (tap) => PortraitTile(
      image: null,
      name: 'Companion',
      description: 'Offline',
      onTap: tap,
    ),
  };
  for (final entry in controls.entries) {
    testWidgets(
      '${entry.key} keeps the same highlight for a press and hold and still taps',
      (tester) async {
        final fixture = Fixture();
        await fixture.open();
        addTearDown(fixture.close);
        var taps = 0;
        const key = Key('feedback-surface');
        await fixture.pump(
          tester,
          page: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 200,
                  height: 160,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Center(child: entry.value(() => taps++)),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final surface = find.byKey(key);
        Future<Uint8List> pixels() async => (await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(surface);
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = await image.toByteData();
            return bytes!.buffer.asUint8List();
          } finally {
            image.dispose();
          }
        }))!;
        final before = await pixels();
        final finger = await tester.startGesture(tester.getCenter(surface));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 250));
        final pressed = await pixels();
        expect(
          pressed,
          isNot(orderedEquals(before)),
          reason: 'Press must show a visible highlight',
        );
        await tester.pump(const Duration(milliseconds: 700));
        expect(
          await pixels(),
          orderedEquals(pressed),
          reason: 'Holding must retain the same highlight as a short press',
        );
        await finger.up();
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(
          await pixels(),
          orderedEquals(before),
          reason: 'Release must clear the highlight',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('app hides long-press tooltips and keeps accessible labels', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    final semantics = tester.ensureSemantics();
    await fixture.pump(tester);
    await tester.pumpAndSettle();
    final menu = find.byKey(const Key('character-menu'));
    await tester.longPress(menu);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('更多'), findsNothing);
    expect(tester.getSemantics(menu).getSemanticsData().label, '更多');
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}
