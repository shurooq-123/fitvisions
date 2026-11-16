import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';
void main() {
  testWidgets('Generation failure offers retry and recovers', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(home: AiGenerationScreen(title: 'Design Clothes', prompt: 'Dress', generator: (_, __) async {
      attempts++;
      if (attempts == 1) throw Exception('offline');
      return base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=');
    })));
    await tester.tap(find.text('Generate')); await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    await tester.ensureVisible(find.text('Generate')); await tester.tap(find.text('Generate')); await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Edit / Save'), findsOneWidget);
  });
}
