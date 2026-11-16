import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiGenerationService {
  static const cloudEndpoint = String.fromEnvironment('FITVISIONS_CLOUD_URL');
  static const localEndpoint = String.fromEnvironment('FITVISIONS_AI_URL');
  static bool get cloudEnabled =>
      Uri.tryParse(cloudEndpoint)?.scheme == 'https';
  static String get endpoint => cloudEnabled ? cloudEndpoint : localEndpoint;
  static const session = String.fromEnvironment('FITVISIONS_AI_SESSION');
  static bool get available =>
      cloudEnabled ||
      (kDebugMode && endpoint == 'http://127.0.0.1:8787' && session.isNotEmpty);

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

  static Future<Uint8List> generate(String prompt, List<Uint8List> images,
      {int? seed}) async {
    final refs = <String>[];
    for (final image in images) {
      refs.add(await reference(image));
    }
    final data = await _post('/generate', {
      'prompt': prompt,
      'images': refs,
      if (seed != null) 'seed': seed,
    });
    return base64Decode((data['image'] as String)
        .replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), ''));
  }

  static Future<Uint8List> generateCandidate(
      String prompt, List<String> references, String model) async {
    final data = await _post('/generate',
        {'prompt': prompt, 'images': references, 'model': model, 'seed': 42});
    if (data['model'] != model) {
      throw Exception(
          'Restart the AI bridge to enable verified model comparisons.');
    }
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
      if (cloudEnabled) {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token == null) throw Exception('Please sign in before generating.');
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      } else {
        request.headers.set('x-fitvisions-session', session);
      }
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
      throw Exception(cloudEnabled
          ? 'Cannot reach AI. Check your internet connection and try again.'
          : 'The local AI trial is disconnected. Keep the laptop server running.');
    } finally {
      client.close(force: true);
    }
  }
}
