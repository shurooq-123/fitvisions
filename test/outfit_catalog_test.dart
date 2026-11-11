import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/outfit_catalog.dart';
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
  testWidgets('Clothes design offers an optional personal photo',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    expect(find.text('Personal photo (optional)'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.byKey(const ValueKey('Colour palette')), findsNothing);
  });
}
