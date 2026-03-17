import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_settings_provider.dart';

/// Theme selection screen
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeSettingsProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Theme'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Choose your preferred appearance. Light and dark modes can help reduce eye strain in different lighting conditions.',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(height: 20),
            CupertinoListSection.insetGrouped(
              children: AppThemeMode.values.map((mode) {
                return CupertinoListTile(
                  title: Text(mode.displayName),
                  subtitle: Text(mode.shortDescription),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(mode.icon, size: 20),
                  ),
                  trailing: currentThemeMode == mode
                      ? const Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          color: CupertinoColors.activeBlue,
                        )
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Preview section
            _buildThemePreview(context, currentThemeMode),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context, AppThemeMode mode) {
    final isDark =
        mode == AppThemeMode.dark ||
        (mode == AppThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.black
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
            ),
            child: Column(
              children: [
                // Mock navigation bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.darkBackgroundGray
                        : CupertinoColors.systemBackground,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Sample View',
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Mock content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 200,
                          decoration: BoxDecoration(
                            color: isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
