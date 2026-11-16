import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/services/avatar_prompt.dart';
import 'package:fitvisions/widgets/measurement_guide.dart';
import 'package:fitvisions/screens/create_clothes_screen.dart';
import 'package:fitvisions/screens/personal_cloth_measurement_screen.dart';

void main() {
  testWidgets(
      'Chart fills measurements; units convert without changing physical size',
      (tester) async {
    Map<String, String> values = {};
    String? size;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: BodyMeasurements(
                    onChanged: (v) => values = v, onSize: (v) => size = v)))));
    await tester.ensureVisible(find.text('M'));
    await tester.tap(find.text('M'));
    await tester.pump();
    expect(size, 'M');
    expect(double.parse(values['Chest']!), 93);
    expect(double.parse(values['Waist']!), 75);
    expect(values['Height'], '');
    await tester.ensureVisible(find.byType(DropdownButton<bool>));
    await tester.tap(find.byType(DropdownButton<bool>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inches (in)').last);
    await tester.pumpAndSettle();
    expect(double.parse(values['Chest']!), closeTo(93, .02));
    expect(find.text('Size guide (in)'), findsOneWidget);
    await tester.ensureVisible(find.text('Height'));
    await tester.tap(find.text('Height'));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is BodyMeasurePainter),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Design Clothes skips the body measurements and size chart',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateClothesScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(BodyMeasurements, skipOffstage: false), findsNothing);
    expect(
        find.byKey(const ValueKey('Size'), skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Generate Avatar offers two gallery boxes without height examples',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: PersonalClothMeasurementScreen()));
    expect(find.text('Clothing image'), findsOneWidget);
    expect(find.text('Personal photo (optional)'), findsOneWidget);
    expect(find.text('Height examples'), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
    expect(find.text('5XL'), findsOneWidget);
    final gender = find.byType(DropdownButtonFormField<AvatarGender>);
    expect(tester.getTopLeft(gender).dy,
        greaterThan(tester.getTopLeft(find.text('Shoulders').first).dy));
    await tester.ensureVisible(gender);
    await tester.tap(gender);
    await tester.pumpAndSettle();
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
  });
  testWidgets('Ready-made form only offers personal photo inputs',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: PersonalClothMeasurementScreen(readyMade: true)));
    expect(find.text('Clothing photo\n(optional)'), findsNothing);
    expect(find.text('Choose a ready-made outfit'), findsNothing);
    expect(find.text('Personal photo (optional)'), findsOneWidget);
    expect(find.text('Personal photo — Camera'), findsNothing);
    expect(find.byType(BodyMeasurements), findsOneWidget);
  });
}
