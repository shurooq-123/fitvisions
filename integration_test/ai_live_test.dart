import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';
import 'package:fitvisions/services/avatar_prompt.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Live Cloudflare clothing and measurement avatar generation',
      (tester) async {
    for (final avatar in [false, true]) {
      await tester.pumpWidget(MaterialApp(
          home: AiGenerationScreen(
        key: ValueKey(avatar),
        title: avatar ? 'Generate Avatar' : 'Create Clothes',
        avatar: avatar,
        measurements: avatar
            ? const {
                'Height': '175',
                'Weight': '75',
                'Chest': '100',
                'Waist': '85',
                'Hips': '100'
              }
            : const {},
        prompt: avatar
            ? avatarPrompt(const {
                'Height': '175',
                'Weight': '75',
                'Chest': '100',
                'Waist': '85',
                'Hips': '100'
              })
            : 'Fashion product photograph of a long emerald green Eid abaya with gold embroidery and long sleeves on a headless mannequin. Ivory studio background. No text.',
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate'));
      final deadline = DateTime.now().add(const Duration(minutes: 4));
      while (find.byType(Image).evaluate().isEmpty &&
          DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 500)));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget,
          reason:
              'Live ${avatar ? "avatar" : "clothing"} should display a generated image.');
      expect(find.text('Edit / Save'), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    }
  }, timeout: const Timeout(Duration(minutes: 9)));
}
