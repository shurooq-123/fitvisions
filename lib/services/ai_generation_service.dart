import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class AiGenerationService {
  static const endpoint = String.fromEnvironment('FITVISIONS_AI_URL');
  static const session = String.fromEnvironment('FITVISIONS_AI_SESSION');
  static bool get available =>
      kDebugMode && endpoint == 'http://127.0.0.1:8787' && session.isNotEmpty;

  static Future<String> reference(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale = 480 /
        (descriptor.width > descriptor.height
            ? descriptor.width
            : descriptor.height);
    final codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round(),
        targetHeight: (descriptor.height * scale).round());
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    if (png == null) throw Exception('Could not prepare the photo.');
    return base64Encode(png.buffer.asUint8List());
  }

  static Future<Uint8List> generate(
      String prompt, List<Uint8List> images) async {
    final refs = <String>[];
    for (final image in images) {
      refs.add(await reference(image));
    }
    final data = await _post('/generate', {'prompt': prompt, 'images': refs});
    return base64Decode((data['image'] as String)
        .replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), ''));
  }

  static Future<String> estimateSkin(Uint8List photo) async {
    final data = await _post('/skin-tone', {'image': await reference(photo)});
    final tone = data['tone'];
    if (!['Fair', 'Light', 'Medium', 'Tan', 'Deep', 'Unknown'].contains(tone)) {
      throw Exception('Could not estimate the tone. Please choose manually.');
    }
    return tone as String;
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    if (!available) {
      throw Exception(
          'AI trial is not connected. Start the local trial server and emulator build.');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(Uri.parse('$endpoint$path'));
      request.headers.contentType = ContentType.json;
      request.headers.set('x-fitvisions-session', session);
      request.write(jsonEncode(body));
      final response =
          await request.close().timeout(const Duration(seconds: 190));
      final data = jsonDecode(await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 190))) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Generation failed.');
      }
      return data;
    } on SocketException {
      throw Exception(
          'The local AI trial is disconnected. Keep the laptop server running.');
    } finally {
      client.close(force: true);
    }
  }
}
