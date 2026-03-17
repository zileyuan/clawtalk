import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

/// Language selector widget for picking app language
class LanguageSelector extends ConsumerWidget {
  final bool showCurrentOnly;
  final VoidCallback? onTap;

  const LanguageSelector({super.key, this.showCurrentOnly = false, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(
      settingsProvider.select((s) => s.language),
    );

    if (showCurrentOnly) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLanguage.code.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(CupertinoIcons.chevron_down, size: 14),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
        ),
        const SizedBox(height: 8),
        CupertinoListSection.insetGrouped(
          children: AppLanguage.values.map((language) {
            final isSelected = currentLanguage == language;

            return CupertinoListTile(
              title: Text(language.displayName),
              subtitle: Text(_getNativeName(language)),
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
      ],
    );
  }

  String _getNativeName(AppLanguage language) {
    final nativeNames = {
      AppLanguage.english: 'English',
      AppLanguage.chinese: '简体中文',
      AppLanguage.japanese: '日本語',
      AppLanguage.korean: '한국어',
      AppLanguage.spanish: 'Español',
      AppLanguage.french: 'Français',
      AppLanguage.german: 'Deutsch',
    };
    return nativeNames[language] ?? '';
  }
}

/// Compact language selector for use in app bars or inline
class LanguageSelectorCompact extends ConsumerWidget {
  final VoidCallback? onTap;

  const LanguageSelectorCompact({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(
      settingsProvider.select((s) => s.language),
    );

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.globe, size: 16),
            const SizedBox(width: 6),
            Text(
              currentLanguage.code.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Language badge for display purposes
class LanguageBadge extends StatelessWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback? onTap;

  const LanguageBadge({
    super.key,
    required this.language,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue.withAlpha(26)
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language.code.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.label,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              language.displayName,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
