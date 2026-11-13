import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('intentional overflow is observed as a failed layout signal', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 100,
          child: Row(children: [SizedBox(width: 2000, height: 50)]),
        ),
      ),
    );
    expect(tester.takeException().toString(), contains('overflowed'));
    await tester.pumpWidget(const SizedBox());
  });
}
