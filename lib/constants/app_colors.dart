import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFCED1C6);
  static const Color primary = Color(0xFF574543);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;

  static Color adaptive(BuildContext context, Color light, Color dark) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static Color page(BuildContext context, [Color light = background]) =>
      adaptive(context, light, const Color(0xFF1C1E1B));

  static Color panel(BuildContext context,
          [Color light = const Color(0xFFEFEFEF)]) =>
      adaptive(context, light, const Color(0xFF2B2E28));

  static Color field(BuildContext context, [Color light = Colors.white]) =>
      adaptive(context, light, const Color(0xFF383B34));

  static Color ink(BuildContext context, [Color light = Colors.black]) =>
      adaptive(context, light, const Color(0xFFECECE4));

  static Color muted(BuildContext context, [Color light = Colors.black54]) =>
      adaptive(context, light, const Color(0xFFC0C3B9));

  static Color accent(BuildContext context,
          [Color light = const Color(0xFF51227D)]) =>
      adaptive(context, light, const Color(0xFFE1BBFA));
}
