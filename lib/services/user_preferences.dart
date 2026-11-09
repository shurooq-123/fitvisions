import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static String? get userId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> read(String name,
      {String? accountId}) async {
    final uid = accountId ?? userId;
    if (uid == null) return {};
    try {
      final prefs = await SharedPreferences.getInstance();
      return Map<String, dynamic>.from(
          jsonDecode(prefs.getString('$uid:$name') ?? '{}'));
    } catch (_) {
      return {};
    }
  }

  static Future<void> write(String name, Map<String, dynamic> data,
      {String? accountId}) async {
    final uid = accountId ?? userId;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$uid:$name', jsonEncode(data));
  }
}
