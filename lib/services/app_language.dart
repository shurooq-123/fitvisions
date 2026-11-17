import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/arabic.dart';

class AppLanguage {
  static final locale = ValueNotifier(const Locale('en'));
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    locale.value =
        Locale(prefs.getString('fitvisions.language') == 'ar' ? 'ar' : 'en');
  }

  static Future<void> set(String code) async {
    if (code != 'ar' && code != 'en') return;
    locale.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fitvisions.language', code);
  }

  static void watch(BuildContext context) {
    Localizations.localeOf(context);
  }

  static Widget observe(BuildContext context, Widget Function() build) {
    watch(context);
    return build();
  }
}

String tr(String text) {
  if (text.contains(' | ') && RegExp(r'[\u0600-\u06ff]').hasMatch(text)) {
    final pieces = text.split(' | ');
    if (pieces.length == 2)
      return AppLanguage.locale.value.languageCode == 'ar'
          ? pieces[0]
          : pieces[1];
  }
  if (AppLanguage.locale.value.languageCode != 'ar') return text;
  final exact = arabic[text];
  if (exact != null) return exact;
  if (text.contains('\n')) return text.split('\n').map(tr).join('\n');
  final unread = RegExp(r'^Notifications \((\d+) unread\)$').firstMatch(text);
  if (unread != null) return 'الإشعارات (${unread[1]} غير مقروءة)';
  final months = RegExp(r'^(\d+) [Mm]onths?$').firstMatch(text);
  if (months != null) return '${months[1]} شهر';
  final enterDigits = RegExp(r'^Enter (\d+) digits$').firstMatch(text);
  if (enterDigits != null) return 'أدخل ${enterDigits[1]} أرقام';
  if (text.startsWith('Enter ') && arabic.containsKey(text.substring(6)))
    return 'أدخل ${tr(text.substring(6))}';
  final colon = text.indexOf(': ');
  if (colon > 0 && arabic.containsKey(text.substring(0, colon)))
    return '${tr(text.substring(0, colon))}: ${tr(text.substring(colon + 2))}';
  return text;
}

String? trError(String? text) => text == null ? null : tr(text);

/// Translates presentation only. Stored answers, IDs and AI prompts stay stable.
class AppText extends StatelessWidget {
  const AppText(this.data,
      {super.key,
      this.style,
      this.strutStyle,
      this.textAlign,
      this.textDirection,
      this.locale,
      this.softWrap,
      this.overflow,
      this.textScaleFactor,
      this.textScaler,
      this.maxLines,
      this.semanticsLabel,
      this.textWidthBasis,
      this.textHeightBehavior,
      this.selectionColor});
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (_, language, __) => Text(tr(data),
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale ?? language,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler ??
              (textScaleFactor == null
                  ? null
                  : TextScaler.linear(textScaleFactor!)),
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor));
}
