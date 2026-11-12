import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/ui/core/controls.dart';
import 'package:xiaoyu/ui/core/design.dart';

import '../support/fixture.dart';

void main() {
  testWidgets(
    'tab accessibility has one selected target and changes with navigation',
    (tester) async {
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      final handle = tester.ensureSemantics();
      await fixture.pump(tester);
      await tester.pumpAndSettle();
      SemanticsNode node(int index) =>
          tester.getSemantics(find.byKey(Key('tab-accessibility-$index')));
      expect(node(0).flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node(1).flagsCollection.isSelected, ui.Tristate.isFalse);
      expect(node(1).getSemanticsData().label, '我的');
      expect(
        tester.getSize(find.byKey(const Key('tab-accessibility-1'))).height,
        greaterThanOrEqualTo(48),
      );
      node(1).owner!.performAction(node(1).id, ui.SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(node(1).flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node(0).flagsCollection.isSelected, ui.Tristate.isFalse);
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    },
  );

  testWidgets(
    'switch supports expanded hit area, toggled semantics and disabling',
    (tester) async {
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      final handle = tester.ensureSemantics();
      var value = false;
      var enabled = true;
      late StateSetter rebuild;
      await fixture.pump(
        tester,
        page: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return AppToggle(
                title: const Text('Memory'),
                value: value,
                onChanged: enabled
                    ? (next) => setState(() => value = next)
                    : null,
              );
            },
          ),
        ),
      );
      await tester.tapAt(
        tester.getTopRight(find.byType(LiquidGlassSwitch)) +
            const Offset(-30, -6),
      );
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final toggle = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Memory' &&
            w.properties.toggled != null,
      );
      expect(
        tester.getSemantics(toggle).flagsCollection.isToggled,
        ui.Tristate.isTrue,
      );
      rebuild(() => enabled = false);
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byType(LiquidGlassSwitch)));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(
        tester.getSemantics(toggle).flagsCollection.isEnabled,
        ui.Tristate.isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    },
  );

  testWidgets(
    'long glass button fits large text; ordinary fields keep password private',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      final input = TextEditingController(text: 'offline-only');
      addTearDown(input.dispose);
      await fixture.pump(
        tester,
        page: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppButton(
                onPressed: () {},
                child: const Text(
                  'A long action that must wrap onto multiple lines',
                ),
              ),
              AppField(controller: input, label: 'Key', password: true),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lens = find.byType(LiquidGlassButton);
      final label = find.text(
        'A long action that must wrap onto multiple lines',
      );
      expect(tester.getRect(lens).contains(tester.getTopLeft(label)), isTrue);
      expect(
        tester.getRect(lens).contains(tester.getBottomRight(label)),
        isTrue,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
