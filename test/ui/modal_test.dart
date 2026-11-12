import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/ui/account_editor.dart';
import 'package:xiaoyu/ui/core/widgets.dart';
import 'package:xiaoyu/ui/core/design.dart';

import '../support/fixture.dart';
import 'layout_matrix_test.dart' show assertReachable, operation;

void main() {
  for (final locale in ['zh', 'en']) {
    for (final keyboard in [false, true]) {
      testWidgets(
        'real sheet and confirmation remain dismissible $locale keyboard=$keyboard',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(568, 320);
          tester.view.viewInsets = FakeViewPadding(bottom: keyboard ? 140 : 0);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.view.resetViewInsets();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final fixture = Fixture(locale: locale);
          await fixture.open();
          addTearDown(fixture.close);
          await fixture.pump(
            tester,
            page: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      key: const Key('open-sheet'),
                      onPressed: () => sheet<String>(
                        context,
                        const VoicePicker(selected: 'Serena'),
                      ),
                      child: const Text('Voice'),
                    ),
                    TextButton(
                      key: const Key('open-confirm'),
                      onPressed: () => confirm(
                        context,
                        context.s.callCostTitle,
                        context.s.callCostBody,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.tap(find.byKey(const Key('open-sheet')));
          await tester.pumpAndSettle();
          await assertReachable(tester, 'voice-close', const Size(568, 320));
          await tester.tap(find.byKey(const Key('voice-close')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('open-confirm')));
          await tester.pumpAndSettle();
          await assertReachable(tester, 'confirm-cancel', const Size(568, 320));
          await tester.tap(operation(tester, 'confirm-cancel'));
          await tester.pumpAndSettle();
          expect(find.byType(LiquidGlassAlertDialog), findsNothing);
          await tester.pumpAndSettle();
          expect(find.byType(ConfirmationPanel), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
