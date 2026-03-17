import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

/// Language selection screen
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Language'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Select your preferred language for the app interface.',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(height: 20),
            CupertinoListSection.insetGrouped(
              header: Text(
                'Available Languages'.toUpperCase(),
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              children: AppLanguage.values.map((language) {
                final isSelected = currentLanguage == language;

                return CupertinoListTile(
                  title: Text(language.displayName),
                  subtitle: Text(_getLanguageSubtitle(language)),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CupertinoColors.activeBlue.withAlpha(26)
                          : CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        language.code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          color: CupertinoColors.activeBlue,
                        )
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage(language);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'More languages coming soon.',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                  color: CupertinoColors.tertiaryLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageSubtitle(AppLanguage language) {
    final subtitles = {
      AppLanguage.english: 'Default',
      AppLanguage.chinese: '简体中文',
      AppLanguage.japanese: '日本語',
      AppLanguage.korean: '한국어',
      AppLanguage.spanish: 'Español',
      AppLanguage.french: 'Français',
      AppLanguage.german: 'Deutsch',
    };
    return subtitles[language] ?? '';
  }
}
