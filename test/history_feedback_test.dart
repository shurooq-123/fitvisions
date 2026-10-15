import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/feedback_message.dart';
import 'package:fitvisions/widgets/history_preview.dart';

void main() {
  testWidgets('Feedback shows message and exactly the submitted stars',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: FeedbackMessage({
      'email': 'user@example.com',
      'rating': 3,
      'message': 'Loved the outfit'
    }))));
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    expect(find.text('Loved the outfit'), findsOneWidget);
  });
  testWidgets('Legacy history stays readable and corrupt previews do not crash',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HistoryPreview({'previewBase64': '%%%'}))));
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
