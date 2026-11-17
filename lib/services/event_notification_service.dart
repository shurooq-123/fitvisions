import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Only record IDs leave the app; the server resolves recipient and payment terms.
class EventNotificationService {
  static const key = 'fitvisions.pendingEventEmails';
  static bool sending = false;
  static Timer? timer;
  static Future<void> start() async {
    timer ??= Timer.periodic(const Duration(seconds: 45), (_) => flush());
    FirebaseAuth.instance.authStateChanges().listen((_) => flush());
    await flush();
  }

  static Future<void> enqueue(String kind, String id, String message) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(key) ?? [];
      final entry = jsonEncode({'uid': uid, 'kind': kind, 'id': id});
      if (!pending.contains(entry)) {
        await prefs.setStringList(key, [...pending, entry]);
        NotificationService.messenger.currentState?.showSnackBar(SnackBar(
            content: Text(message),
            action: SnackBarAction(
                label: 'Notifications',
                onPressed: () => NotificationService.navigator.currentState
                    ?.pushNamed('/notifications'))));
      }
      unawaited(flush());
    } catch (_) {
      NotificationService.messenger.currentState?.showSnackBar(const SnackBar(
          content: Text(
              'تم الحفظ، لكن تعذر تجهيز إشعار البريد. | Saved, but the email notification could not be queued.')));
    }
  }

  static Future<void> flush() async {
    if (sending) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    const cloud = String.fromEnvironment('FITVISIONS_CLOUD_URL');
    final url = Uri.tryParse(cloud)?.scheme == 'https'
        ? cloud
        : kDebugMode
            ? 'http://127.0.0.1:8789'
            : '';
    if (url.isEmpty) return;
    sending = true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final item in List<String>.from(prefs.getStringList(key) ?? [])) {
        final event = jsonDecode(item) as Map<String, dynamic>;
        if (event['uid'] != user.uid) continue;
        final token = await user.getIdToken();
        if (FirebaseAuth.instance.currentUser?.uid != user.uid) break;
        final request = await client.postUrl(Uri.parse('$url/event'));
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'kind': event['kind'], 'id': event['id']}));
        final response =
            await request.close().timeout(const Duration(seconds: 25));
        await response.drain<void>().timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final remaining = prefs.getStringList(key) ?? [];
          remaining.remove(item);
          await prefs.setStringList(key, remaining);
        } else {
          break;
        }
      }
    } catch (_) {
      // Persisted queue retries after reconnection; never claim delivery on failure.
    } finally {
      client.close(force: true);
      sending = false;
    }
  }
}
