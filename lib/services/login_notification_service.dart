import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginNotificationService {
  static Future<bool> send() async {
    if (!kDebugMode) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return false;
      final request = await client.postUrl(Uri.parse('http://127.0.0.1:8789/login'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close().timeout(const Duration(seconds: 30));
      await response.drain<void>().timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
