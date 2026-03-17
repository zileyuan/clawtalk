import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_settings_provider.dart';
import '../widgets/settings_tile.dart';
import 'about_screen.dart';
import 'language_settings_screen.dart';
import 'theme_settings_screen.dart';

/// Main settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),

            // Appearance Section
            _buildSectionHeader(context, 'Appearance'),
            CupertinoListSection.insetGrouped(
              children: [
                SettingsTile(
                  icon: CupertinoIcons.paintbrush,
                  iconColor: AppColors.primary,
                  title: 'Theme',
                  subtitle: settings.themeMode.displayName,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const ThemeSettingsScreen(),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  icon: CupertinoIcons.globe,
                  iconColor: AppColors.success,
                  title: 'Language',
                  subtitle: settings.language.displayName,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Notifications Section
            _buildSectionHeader(context, 'Notifications & Sound'),
            CupertinoListSection.insetGrouped(
              children: [
                SettingsTile.switchTile(
                  icon: CupertinoIcons.bell,
                  iconColor: AppColors.warning,
                  title: 'Notifications',
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleNotifications();
                  },
                ),
                SettingsTile.switchTile(
                  icon: CupertinoIcons.speaker_2,
                  iconColor: AppColors.info,
                  title: 'Sound',
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleSound();
                  },
                ),
                SettingsTile.switchTile(
                  icon: CupertinoIcons.hand_draw,
                  iconColor: AppColors.primary,
                  title: 'Haptic Feedback',
                  value: settings.hapticEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleHaptic();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Privacy Section
            _buildSectionHeader(context, 'Privacy & Data'),
            CupertinoListSection.insetGrouped(
              children: [
                SettingsTile.switchTile(
                  icon: CupertinoIcons.chart_bar,
                  iconColor: CupertinoColors.systemIndigo,
                  title: 'Analytics',
                  subtitle: 'Help improve the app',
                  value: settings.analyticsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleAnalytics();
                  },
                ),
                SettingsTile(
                  icon: CupertinoIcons.trash,
                  iconColor: AppColors.error,
                  title: 'Clear Data',
                  subtitle: 'Remove all local data',
                  titleColor: AppColors.error,
                  onTap: () => _showClearDataConfirmation(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // About Section
            _buildSectionHeader(context, 'About'),
            CupertinoListSection.insetGrouped(
              children: [
                SettingsTile(
                  icon: CupertinoIcons.info_circle,
                  iconColor: AppColors.secondary,
                  title: 'About ClawTalk',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel,
            ),
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will remove all settings and cached data. This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(settingsProvider.notifier).clearData();
              _showClearedConfirmation(context);
            },
            child: const Text('Clear'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearedConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Data Cleared'),
        content: const Text('All local data has been removed.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
