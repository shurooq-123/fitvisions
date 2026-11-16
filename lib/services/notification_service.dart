import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> backgroundNotification(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payloads are displayed by the OS. History is written by the server.
}

class NotificationService {
  static final navigator = GlobalKey<NavigatorState>();
  static final messenger = GlobalKey<ScaffoldMessengerState>();
  static final status = ValueNotifier<String?>(null);
  static String? _registeredUid;

  static Future<void> start() async {
    FirebaseMessaging.onBackgroundMessage(backgroundNotification);
    FirebaseMessaging.onMessage.listen((message) {
      if (FirebaseAuth.instance.currentUser?.uid != message.data['uid']) return;
      messenger.currentState?.showSnackBar(SnackBar(
          content:
              Text(message.notification?.body ?? 'You have a new notification'),
          action: SnackBarAction(
              label: 'View',
              onPressed: () =>
                  navigator.currentState?.pushNamed('/notifications'))));
    });
    void open(RemoteMessage message) {
      if (FirebaseAuth.instance.currentUser?.uid == message.data['uid']) {
        navigator.currentState?.pushNamed('/notifications');
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen(open);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => open(initial));
    }
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      try {
        if (_registeredUid != null && _registeredUid != user?.uid) {
          // Invalidate the device token on account switch, preventing delivery to a former account.
          await FirebaseMessaging.instance.deleteToken();
        }
        _registeredUid = user?.uid;
        if (user != null) await enable();
      } catch (_) {
        status.value =
            'Push connection unavailable. Open Notifications to retry.';
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await _saveToken(token);
      } catch (_) {
        status.value =
            'Could not register this device. Retry in Notifications.';
      }
    });
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(token)
        .set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> enable() async {
    try {
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        status.value =
            'Notifications are disabled. Enable them in your phone settings.';
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(token);
        status.value = null;
      }
    } catch (_) {
      status.value = 'Could not connect push notifications. Tap Retry.';
    }
  }
}
