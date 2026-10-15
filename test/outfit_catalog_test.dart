import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/outfit_catalog.dart';
import 'package:fitvisions/screens/ready_outfits_screen.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';

void main() {
  test('Every collection has separate male and female outfits', () {
    for (final category in outfitCategories) {
      for (final gender in ['Male', 'Female']) {
        final outfits = outfitsFor(category, gender);
        expect(outfits, isNotEmpty);
        expect(
            outfits.every((o) => o.gender == gender && o.category == category),
            isTrue);
      }
    }
    expect(outfitsFor('Wedding', 'Female').length, greaterThanOrEqualTo(3));
    expect(outfitReferences.map((o) => o.path).toSet().length,
        outfitReferences.length);
  });
  testWidgets('Entry displays only three collections before gender selection',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadyOutfitsScreen()));
    for (final category in outfitCategories) {
      expect(find.text(category), findsOneWidget);
    }
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.tap(find.text('Wedding'));
    await tester.pumpAndSettle();
    expect(
        find.text('Select a gender to see available outfits.'), findsOneWidget);
    expect(find.text('Omani groom'), findsNothing);
    expect(find.text('Lace ball gown'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    expect(find.text('Omani groom'), findsOneWidget);
    expect(find.text('Lace ball gown'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();
    expect(find.text('Omani groom'), findsNothing);
    expect(find.text('Lace ball gown'), findsOneWidget);
  });
  testWidgets('Clothes design offers optional face instead of colour palette',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    expect(find.text('Face photo (optional)'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.byKey(const ValueKey('Colour palette')), findsNothing);
  });
}
