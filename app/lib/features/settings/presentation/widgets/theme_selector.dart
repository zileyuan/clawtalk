import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_settings_provider.dart';

/// Theme selector widget for picking light/dark/system mode
class ThemeSelector extends ConsumerWidget {
  final bool showLabels;
  final bool showPreview;

  const ThemeSelector({
    super.key,
    this.showLabels = true,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels) ...[
          Text(
            'Appearance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: AppThemeMode.values.map((mode) {
            final isSelected = currentMode == mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CupertinoColors.activeBlue.withAlpha(26)
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey4,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode.icon,
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                          size: 28,
                        ),
                        if (showLabels) ...[
                          const SizedBox(height: 8),
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.label,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (showPreview) ...[
          const SizedBox(height: 16),
          _buildPreview(context, currentMode),
        ],
      ],
    );
  }

  Widget _buildPreview(BuildContext context, AppThemeMode mode) {
    final isDark = mode == AppThemeMode.dark;
    final bgColor = isDark
        ? CupertinoColors.black
        : CupertinoColors.systemBackground;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
      ),
      child: Center(
        child: Text(
          mode == AppThemeMode.system ? 'Auto' : '${mode.displayName} Mode',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Compact theme selector for inline use
class ThemeSelectorCompact extends ConsumerWidget {
  const ThemeSelectorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeSettingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppThemeMode.values.map((mode) {
          final isSelected = currentMode == mode;
          return CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: () {
              ref.read(settingsProvider.notifier).setThemeMode(mode);
            },
            child: Icon(
              mode.icon,
              size: 20,
              color: isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey,
            ),
          );
        }).toList(),
      ),
    );
  }
}
