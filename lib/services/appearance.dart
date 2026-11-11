import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appearance {
  static const _key = 'fitvisions.darkMode';
  static final mode = ValueNotifier(ThemeMode.light);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    mode.value =
        preferences.getBool(_key) == true ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDark(bool dark) async {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, dark);
  }
}
