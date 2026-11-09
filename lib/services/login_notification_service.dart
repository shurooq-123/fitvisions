import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginNotificationService {
  static const cloudEndpoint = String.fromEnvironment('FITVISIONS_CLOUD_URL');
  static bool get cloudEnabled =>
      Uri.tryParse(cloudEndpoint)?.scheme == 'https';
  static Future<bool> send(
      {bool registration = false, bool passwordChanged = false}) async {
    if (!cloudEnabled && !kDebugMode) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final token =
          await FirebaseAuth.instance.currentUser?.getIdToken(passwordChanged);
      if (token == null) return false;
      final path = passwordChanged
          ? 'password-changed'
          : registration
              ? 'registration'
              : 'login';
      final request = await client.postUrl(Uri.parse(
          '${cloudEnabled ? cloudEndpoint : 'http://127.0.0.1:8789'}/$path'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      await response.drain<void>().timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
