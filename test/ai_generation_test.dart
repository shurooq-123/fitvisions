import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/ai_generation_screen.dart';
import 'package:fitvisions/services/ai_generation_service.dart';

void main() {
  testWidgets('AI waits for user confirmation and explains disconnected trial',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: AiGenerationScreen(
            title: 'Generate Avatar',
            prompt: 'test proportions',
            avatar: true)));
    expect(find.textContaining('sent to Cloudflare'), findsOneWidget);
    expect(find.textContaining('not guaranteed'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();
    expect(find.textContaining('AI trial is not connected'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
  });
  test('Reference resize preserves aspect ratio and meets provider limit',
      () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.green, BlendMode.src);
    final picture = recorder.endRecording();
    final source = await picture.toImage(1200, 600);
    final data = await source.toByteData(format: ui.ImageByteFormat.png);
    final encoded =
        await AiGenerationService.reference(data!.buffer.asUint8List());
    final codec = await ui.instantiateImageCodec(base64Decode(encoded));
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 480);
    expect(frame.image.height, 240);
    frame.image.dispose();
    codec.dispose();
    source.dispose();
    picture.dispose();
  });
}
