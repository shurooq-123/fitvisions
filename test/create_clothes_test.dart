import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';

void main() {
  testWidgets('Required design choices survive review and editing',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    await tester.pumpAndSettle();
    for (final entry in {
      'Gender / clothing style': 'Female',
      'Age group': 'Adult (18–29)',
      'Occasion': 'Birthday',
      'Outfit type': 'Other outfits',
      'Style': 'Evening',
      'Silhouette': 'A-line',
      'Length': 'Long',
      'Neckline': 'Off-shoulder',
      'Sleeves': 'Long sleeves',
      'Fit': 'Regular',
      'Fabric': 'Satin',
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
    final dynamic state = tester.state(find.byType(CreateClothesScreen));
    final Map<String, List<String>> current =
        Map<String, List<String>>.from(state.questions);
    for (final entry in current.entries) {
      if (state.answers[entry.key] == null && !entry.key.contains('(optional)'))
        state.answers[entry.key] = entry.value.first;
    }
    state.setState(() {});
    await tester.pump();
    await tester.ensureVisible(find.text('Review design'));
    await tester.tap(find.text('Review design'));
    await tester.pumpAndSettle();
    expect(find.text('Your Clothing Design'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);

    await tester.ensureVisible(find.text('Edit choices'));
    await tester.tap(find.text('Edit choices'));
    await tester.pumpAndSettle();
    expect(find.text('Birthday'), findsOneWidget);
  });
}
