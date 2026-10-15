import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/clothing_library.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All clothing references are bundled PNG images', () async {
    for (final path in clothingTemplates.keys) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000));
      expect(data.buffer.asUint8List().take(4), [137, 80, 78, 71]);
    }
  });
  testWidgets('Bundled reference reaches generation without a filesystem path', (tester) async {
    int count = 0;
    await tester.pumpWidget(MaterialApp(home: AiGenerationScreen(
      title: 'Create Clothes', prompt: 'Use the garment reference',
      photos: const ['images/omani_men.png'],
      generator: (prompt, photos) async {
        count = photos.length;
        expect(photos.single.take(4), [137, 80, 78, 71]);
        return photos.single;
      },
    )));
    await tester.tap(find.text('Generate'));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(seconds: 1)); });
    await tester.pumpAndSettle();
    expect(count, 1);
    expect(find.text('Edit / Save'), findsOneWidget);
  });
}
