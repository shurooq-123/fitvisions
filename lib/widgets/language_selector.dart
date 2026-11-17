import 'package:flutter/material.dart';
import '../services/app_language.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (_, locale, __) => ListTile(
          leading: const Icon(Icons.language),
          title: const AppText('Language'),
          trailing: DropdownButton<String>(
              value: locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية'))
              ],
              onChanged: (value) {
                if (value != null) AppLanguage.set(value);
              })));
}
