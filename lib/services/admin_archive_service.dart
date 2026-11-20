import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminArchiveService {
  static Future<void> archive(String uid) async {
    if (!kDebugMode) {
      await FirebaseFunctions.instance
          .httpsCallable('archiveUser')
          .call({'uid': uid});
      return;
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('Please sign in again.');
      final request =
          await client.postUrl(Uri.parse('http://127.0.0.1:8790/archive'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'uid': uid}));
      final response =
          await request.close().timeout(const Duration(seconds: 45));
      final body = jsonDecode(await utf8.decoder.bind(response).join()) as Map;
      if (response.statusCode != 200)
        throw FirebaseFunctionsException(
            code: 'failed-precondition', message: body['error']?.toString() ?? 'Could not archive this account.');
    } finally {
      client.close(force: true);
    }
  }
}
