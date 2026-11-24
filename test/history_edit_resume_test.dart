import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';

void main() {
  testWidgets(
      'History avatar edits preserve saved image reference and accept body measurements without weight',
      (tester) async {
    final bytes = File('images/bridal_satin.png').readAsBytesSync();
    String? sent;
    int references = 0;
    await tester.pumpWidget(MaterialApp(
        home: AiGenerationScreen(
            title: 'Edit avatar',
            prompt: 'Preserve outfit',
            avatar: true,
            openHistoryEditor: true,
            initialOutput: bytes,
            measurements: const {
              'Height': '170',
              'Chest': '90',
              'Waist': '75',
              'Hips': '95'
            },
            subscriptionCheck: () async => true,
            generator: (prompt, photos) async {
              sent = prompt;
              references = photos.length;
              return bytes;
            })));
    await tester.pumpAndSettle();
    final dynamic state =
        tester.state(find.byType(AiGenerationScreen, skipOffstage: false));
    state.measures['Waist'].text = '1';
    state.editMeasurement('Waist', '1');
    await tester.runAsync(() async {
      await state.generate(edit: true);
    });
    expect(sent, isNull);
    state.measures['Waist'].text = '85';
    state.editMeasurement('Waist', '85');
    await tester.runAsync(() async {
      await state.generate(edit: true);
    });
    await tester.pump();
    expect(sent, contains('85'));
    expect(references, 1);
    expect(sent, contains('Preserve the garment design'));
  });
}
