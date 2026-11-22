import 'package:flutter/material.dart';
import '../services/app_language.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (_, locale, __) => Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.translate),
                SizedBox(width: 8),
                AppText('Language')
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 8, children: [
                for (final entry in {'en': 'English', 'ar': 'العربية'}.entries)
                  ChoiceChip(
                      label: Text(entry.value),
                      selected: locale.languageCode == entry.key,
                      onSelected: (_) => AppLanguage.set(entry.key)),
              ]),
            ]),
          ));
}
