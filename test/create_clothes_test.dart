import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';

void main() {
  testWidgets('Graduation choices survive review and editing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    for (final entry in {
      'Gender / clothing style': 'Female',
      'Age group': 'Adult (18–29)',
      'Occasion': 'Graduation',
      'Outfit type': 'Graduation dress',
    }.entries) {
      final field = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.value).last);
      await tester.pumpAndSettle();
    }
    final style = find.widgetWithText(OutlinedButton, 'No preference');
    await tester.ensureVisible(style);
    await tester.tap(style);
    await tester.pumpAndSettle();
    for (final action in ['Review design', 'Edit choices']) {
      final button = find.text(action);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Graduation dress'), findsOneWidget);
    }
  });
}
