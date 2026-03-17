import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/themes/app_theme.dart';
import '../../domain/entities/app_settings.dart';
import 'settings_provider.dart';

/// Provider for the current theme mode from settings
final themeSettingsProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// Provider for the current brightness based on theme mode
final brightnessProvider = Provider<Brightness>((ref) {
  final themeMode = ref.watch(themeSettingsProvider);

  switch (themeMode) {
    case AppThemeMode.light:
      return Brightness.light;
    case AppThemeMode.dark:
      return Brightness.dark;
    case AppThemeMode.system:
      // This would need platform brightness from MediaQuery in UI
      return Brightness.light;
  }
});

/// Provider for the current Cupertino theme data based on settings
final appThemeDataProvider = Provider<CupertinoThemeData>((ref) {
  final themeMode = ref.watch(themeSettingsProvider);

  switch (themeMode) {
    case AppThemeMode.light:
      return AppTheme.cupertinoTheme;
    case AppThemeMode.dark:
      return AppTheme.darkTheme;
    case AppThemeMode.system:
      // Return light theme as default, actual system mode handled by CupertinoApp
      return AppTheme.cupertinoTheme;
  }
});

/// Provider to check if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeSettingsProvider);
  return themeMode == AppThemeMode.dark;
});

/// Provider for theme-related settings UI
final themeSettingsNotifierProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsState>(
      (ref) => ThemeSettingsNotifier(ref),
    );

/// State for theme settings
class ThemeSettingsState {
  final AppThemeMode selectedMode;
  final bool isPreviewing;

  const ThemeSettingsState({
    this.selectedMode = AppThemeMode.system,
    this.isPreviewing = false,
  });

  ThemeSettingsState copyWith({
    AppThemeMode? selectedMode,
    bool? isPreviewing,
  }) {
    return ThemeSettingsState(
      selectedMode: selectedMode ?? this.selectedMode,
      isPreviewing: isPreviewing ?? this.isPreviewing,
    );
  }
}

/// Notifier for theme settings UI state
class ThemeSettingsNotifier extends StateNotifier<ThemeSettingsState> {
  final Ref _ref;

  ThemeSettingsNotifier(this._ref) : super(const ThemeSettingsState()) {
    // Initialize with current theme mode
    final currentMode = _ref.read(themeSettingsProvider);
    state = state.copyWith(selectedMode: currentMode);
  }

  /// Select a theme mode (for preview)
  void selectMode(AppThemeMode mode) {
    state = state.copyWith(selectedMode: mode, isPreviewing: true);
  }

  /// Apply the selected theme mode
  Future<void> applyThemeMode() async {
    await _ref.read(settingsProvider.notifier).setThemeMode(state.selectedMode);
    state = state.copyWith(isPreviewing: false);
  }

  /// Cancel preview and revert to saved mode
  void cancelPreview() {
    final savedMode = _ref.read(themeSettingsProvider);
    state = state.copyWith(selectedMode: savedMode, isPreviewing: false);
  }

  /// Reset to system mode
  Future<void> resetToSystem() async {
    await _ref
        .read(settingsProvider.notifier)
        .setThemeMode(AppThemeMode.system);
    state = state.copyWith(
      selectedMode: AppThemeMode.system,
      isPreviewing: false,
    );
  }
}

/// Extension to get display-friendly theme mode names
extension AppThemeModeExtension on AppThemeMode {
  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return CupertinoIcons.sun_max_fill;
      case AppThemeMode.dark:
        return CupertinoIcons.moon_fill;
      case AppThemeMode.system:
        return CupertinoIcons.device_phone_portrait;
    }
  }

  String get shortDescription {
    switch (this) {
      case AppThemeMode.light:
        return 'Light appearance';
      case AppThemeMode.dark:
        return 'Dark appearance';
      case AppThemeMode.system:
        return 'Matches device setting';
    }
  }
}
