import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/screens/photo_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Crop selects right half and saves requested pixel dimensions',
      () async {
    final r = ui.PictureRecorder();
    final c = Canvas(r);
    c.drawRect(const Rect.fromLTWH(0, 0, 200, 100),
        Paint()..color = const Color(0xFFFF0000));
    c.drawRect(const Rect.fromLTWH(100, 0, 100, 100),
        Paint()..color = const Color(0xFF0000FF));
    final p = r.endRecording();
    final source = await p.toImage(200, 100);
    final result = await renderEditedPhoto(
        source, const Rect.fromLTWH(.5, 0, .5, 1), 64, 128, []);
    expect(result.width, 64);
    expect(result.height, 128);
    final bytes = (await result.toByteData())!;
    expect(bytes.getUint8((64 * 64 + 32) * 4), 0);
    expect(bytes.getUint8((64 * 64 + 32) * 4 + 2), 255);
    result.dispose();
    source.dispose();
    p.dispose();
  });
  test('Arrow is saved in exported pixels and invalid dimensions rejected',
      () async {
    final r = ui.PictureRecorder();
    final c = Canvas(r);
    c.drawColor(Colors.white, BlendMode.src);
    final p = r.endRecording();
    final source = await p.toImage(200, 200);
    final out = await renderEditedPhoto(
        source,
        const Rect.fromLTWH(0, 0, 1, 1),
        200,
        200,
        [PhotoMark(Offset(.1, .5), Offset(.9, .5), const Color(0xFFFF0000))]);
    final b = (await out.toByteData())!;
    final i = (100 * 200 + 100) * 4;
    expect(b.getUint8(i), 255);
    expect(b.getUint8(i + 1), lessThan(80));
    await expectLater(
        renderEditedPhoto(source, const Rect.fromLTWH(0, 0, 1, 1), 1, 200, []),
        throwsArgumentError);
    out.dispose();
    source.dispose();
    p.dispose();
  });
}
