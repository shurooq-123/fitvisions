import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/avatar_comparison_screen.dart';

void main() {
  testWidgets(
      'Both model candidates receive identical inputs and a failure does not skip the other',
      (tester) async {
    final bytes = (await tester.runAsync(() async {
      final recorder=ui.PictureRecorder(); Canvas(recorder).drawColor(Colors.grey,BlendMode.src);
      final picture=recorder.endRecording(); final image=await picture.toImage(100,100);
      final data=(await image.toByteData(format:ui.ImageByteFormat.png))!.buffer.asUint8List();
      image.dispose();picture.dispose();return data;
    }))!;
    final calls = <Map<String, dynamic>>[];
    Future<Uint8List> generate(
        String prompt, List<String> refs, String model) async {
      calls.add({'prompt': prompt, 'refs': refs, 'model': model});
      if (model.endsWith('4b')) throw Exception('Test quota failure');
      return bytes;
    }

    await tester.pumpWidget(MaterialApp(
        home: AvatarComparisonScreen(
            bodyImage: bytes,
            measurements: const {
              'Height': '170',
              'Chest': '96',
              'Waist': '78',
              'Hips': '102'
            },
            candidateGenerator: generate)));
    await tester.ensureVisible(find.text('Run comparison'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Run comparison'));
      for (var i = 0; i < 150 && calls.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(calls.length, 2);
    expect(calls[0]['prompt'], calls[1]['prompt']);
    expect(calls[0]['refs'], calls[1]['refs']);
    expect(
        calls.map((c) => c['model']), ['flux-2-klein-4b', 'flux-2-klein-9b']);
    expect(find.text('Test quota failure'), findsOneWidget);
    expect(find.text('Comparison finished. Review each result below.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
