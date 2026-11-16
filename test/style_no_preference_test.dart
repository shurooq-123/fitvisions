import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';
void main() {
 testWidgets('No preference allows review without downstream details', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
  await tester.pumpAndSettle();
  expect(find.text('Browse dress references (50)'), findsNothing);
  for (final e in {'Gender / clothing style':'Female','Age group':'Adult (18–29)','Size':'Medium','Occasion':'Eid'}.entries) {
   final field=find.byKey(ValueKey(e.key));
   await tester.ensureVisible(field); await tester.tap(field); await tester.pumpAndSettle();
   await tester.tap(find.text(e.value).last); await tester.pumpAndSettle();
  }
  final style=find.widgetWithText(OutlinedButton,'No preference');
  await tester.ensureVisible(style); await tester.tap(style); await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Review design')); await tester.tap(find.text('Review design')); await tester.pumpAndSettle();
  expect(find.text('Your Clothing Design'), findsOneWidget);
  expect(find.text('Please select an option'), findsNothing);
 });
}
