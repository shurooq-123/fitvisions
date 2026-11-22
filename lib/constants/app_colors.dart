import 'package:flutter/material.dart';

/// Shared visual palette. Garment swatches and stored values are independent.
class AppColors {
  static const Color background = Color(0xFFFAF0F3);
  static const Color primary = Color(0xFF85465F);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static Color adaptive(BuildContext context, Color light, Color dark) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
  static Color page(BuildContext context, [Color light = background]) =>
      adaptive(context, background, const Color(0xFF211A20));
  static Color panel(BuildContext context,
          [Color light = const Color(0xFFFFFAF8)]) =>
      adaptive(context, const Color(0xFFFFFAF8), const Color(0xFF30242D));
  static Color field(BuildContext context, [Color light = Colors.white]) =>
      adaptive(context, const Color(0xFFFFFCFA), const Color(0xFF3A2B35));
  static Color ink(BuildContext context, [Color light = Colors.black]) =>
      adaptive(context, const Color(0xFF382331), const Color(0xFFFFF1F5));
  static Color muted(BuildContext context, [Color light = Colors.black54]) =>
      adaptive(context, const Color(0xFF745D68), const Color(0xFFD6BDC9));
  static Color accent(BuildContext context, [Color light = primary]) =>
      adaptive(context, primary, const Color(0xFFF1B1CA));
}
