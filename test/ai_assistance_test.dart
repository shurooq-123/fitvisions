import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/ai_assistance_screen.dart';

void main() {
  testWidgets(
      'Related recommendations send prefilled measurements and selected garment',
      (tester) async {
    Map<String, dynamic>? sent;
    await tester.pumpWidget(MaterialApp(
        home: AiAssistanceScreen(
            recommendations: true,
            initialMeasurements: const {
              'Height': '170',
              'Chest': '93',
              'Waist': '75',
              'Hips': '99',
              'Shoulders': '40'
            },
            clothingContext: 'Blue dress, Female',
            request: (p, d) async {
              sent = d;
              return 'A cream jacket and neutral shoes.';
            })));
    await tester.ensureVisible(find.text('Get recommendations'));
    await tester.tap(find.text('Get recommendations'));
    await tester.pumpAndSettle();
    expect(sent!['measurements']['Waist'], '75');
    expect(sent!['preferences'], contains('Blue dress'));
    expect(find.text('A cream jacket and neutral shoes.'), findsOneWidget);
  });

  testWidgets('Chat sends context and preserves failed question for retry',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
        MaterialApp(home: AiAssistanceScreen(request: (path, input) async {
      calls++;
      expect(path, '/chat');
      expect((input['messages'] as List).last['content'], 'Upload help');
      if (calls == 1) throw Exception('Offline');
      return 'Tap clothing photo and select Camera or Gallery.';
    })));
    await tester.enterText(find.byType(TextField), 'Upload help');
    await tester.ensureVisible(find.text('Send'));
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Upload help'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Tap clothing photo and select Camera or Gallery.'),
        findsOneWidget);
    expect(calls, 2);
  });
  testWidgets('Recommendation form prevents empty measurements from calling AI',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: AiAssistanceScreen(
            recommendations: true,
            request: (p, d) async {
              calls++;
              return 'Advice';
            })));
    await tester.ensureVisible(find.text('Get recommendations'));
    await tester.tap(find.text('Get recommendations'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Enter valid measurements and your preferences.'),
        findsOneWidget);
  });
}
