import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';

void main() {
  testWidgets(
      'Other occasion is required and choices survive review and editing',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    for (final entry in {
      'Gender / clothing style': 'Female',
      'Age group': 'Adult (18–29)',
      'Size': 'Medium',
      'Occasion': 'Other',
      'Style': 'Evening',
      'Silhouette': 'A-line',
      'Length': 'Long',
      'Neckline': 'Off-shoulder',
      'Sleeves': 'Long sleeves',
      'Fit': 'Regular',
      'Fabric': 'Satin',
      'Favourite colour': 'Blue',
      'Details': 'Minimal',
    }.entries) {
      if (entry.key == 'Style') {
        final tile = find.widgetWithText(OutlinedButton, entry.value);
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        continue;
      }
      final field = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.value).last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Review design'));
    await tester.tap(find.text('Review design'));
    await tester.pumpAndSettle();
    expect(find.text('Please describe the occasion'), findsOneWidget);
    final other = find.widgetWithText(TextFormField, 'Describe the occasion');
    await tester.ensureVisible(other);
    await tester.enterText(other, 'Graduation');
    await tester.ensureVisible(find.text('Review design'));
    await tester.tap(find.text('Review design'));
    await tester.pumpAndSettle();
    expect(find.text('Your Clothing Design'), findsOneWidget);
    expect(find.text('Graduation'), findsOneWidget);
    expect(find.text('Not specified'), findsOneWidget);
    await tester.ensureVisible(find.text('Edit choices'));
    await tester.tap(find.text('Edit choices'));
    await tester.pumpAndSettle();
    expect(find.text('Graduation'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
  });
}
