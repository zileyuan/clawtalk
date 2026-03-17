import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../themes/app_theme.dart';

/// Provider for the current theme mode.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Provider for the current Cupertino theme data.
final cupertinoThemeProvider = Provider<CupertinoThemeData>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  switch (themeMode) {
    case ThemeMode.dark:
      return AppTheme.darkTheme;
    case ThemeMode.light:
      return AppTheme.cupertinoTheme;
    case ThemeMode.system:
    default:
      // Use system brightness - this will be resolved by the CupertinoApp
      // For now return light theme, the platform will handle dark mode
      return AppTheme.cupertinoTheme;
  }
});

/// Provider for checking if dark mode is active.
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});

/// Notifier for managing theme mode state.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const _themeModeKey = 'theme_mode';

  /// Load saved theme mode.
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);

      if (savedMode != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // Fallback to system theme
      state = ThemeMode.system;
    }
  }

  /// Save theme mode.
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      // Silent fail - theme will reset on next app launch
    }
  }

  /// Set theme mode to light.
  Future<void> setLightMode() async {
    state = ThemeMode.light;
    await _saveThemeMode(ThemeMode.light);
  }

  /// Set theme mode to dark.
  Future<void> setDarkMode() async {
    state = ThemeMode.dark;
    await _saveThemeMode(ThemeMode.dark);
  }

  /// Set theme mode to follow system.
  Future<void> setSystemMode() async {
    state = ThemeMode.system;
    await _saveThemeMode(ThemeMode.system);
  }

  /// Toggle between light and dark mode.
  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      await setLightMode();
    } else if (state == ThemeMode.light) {
      await setDarkMode();
    } else {
      // If system mode, default to light for toggle
      await setLightMode();
    }
  }

  /// Cycle through all theme modes: system -> light -> dark -> system.
  Future<void> cycle() async {
    switch (state) {
      case ThemeMode.system:
        await setLightMode();
        break;
      case ThemeMode.light:
        await setDarkMode();
        break;
      case ThemeMode.dark:
        await setSystemMode();
        break;
    }
  }
}

/// Provider for dynamic theme colors.
final themeColorsProvider = Provider<ThemeColors>((ref) {
  final themeData = ref.watch(cupertinoThemeProvider);
  final brightness = themeData.brightness ?? Brightness.light;
  final isDark = brightness == Brightness.dark;

  return ThemeColors(
    background: isDark ? CupertinoColors.black : CupertinoColors.white,
    surface: isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6,
    primary: themeData.primaryColor,
    secondary: isDark
        ? CupertinoColors.systemGrey.darkColor
        : CupertinoColors.systemGrey,
    text: isDark ? CupertinoColors.white : CupertinoColors.black,
    textSecondary: isDark
        ? CupertinoColors.systemGrey.darkColor
        : CupertinoColors.systemGrey,
    divider: isDark
        ? CupertinoColors.systemGrey.withOpacity(0.2)
        : CupertinoColors.systemGrey4,
  );
});

/// Theme colors data class.
class ThemeColors {
  /// Creates theme colors.
  const ThemeColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.text,
    required this.textSecondary,
    required this.divider,
  });

  /// Background color.
  final Color background;

  /// Surface/card color.
  final Color surface;

  /// Primary color.
  final Color primary;

  /// Secondary color.
  final Color secondary;

  /// Primary text color.
  final Color text;

  /// Secondary text color.
  final Color textSecondary;

  /// Divider color.
  final Color divider;
}
