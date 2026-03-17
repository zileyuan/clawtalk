import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../domain/entities/app_settings.dart';

/// Provider for app settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

/// Provider to check if settings have been loaded
final settingsLoadedProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.id != null;
});

/// Provider for individual settings values
final languageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(settingsProvider).language;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).notificationsEnabled;
});

final soundEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).soundEnabled;
});

final hapticEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).hapticEnabled;
});

/// Notifier for managing app settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final languageCode = prefs.getString(StorageKeys.language);
      final themeModeName = prefs.getString(StorageKeys.themeMode);
      final notificationsEnabled = prefs.getBool(
        StorageKeys.notificationsEnabled,
      );
      final soundEnabled = prefs.getBool(StorageKeys.soundEnabled);
      final hapticEnabled = prefs.getBool(StorageKeys.hapticEnabled);
      final analyticsEnabled = prefs.getBool(StorageKeys.analyticsEnabled);

      state = state.copyWith(
        id: 'app_settings',
        language: languageCode != null
            ? AppLanguage.fromCode(languageCode)
            : AppLanguage.english,
        themeMode: themeModeName != null
            ? AppThemeMode.fromName(themeModeName)
            : AppThemeMode.system,
        notificationsEnabled: notificationsEnabled ?? true,
        soundEnabled: soundEnabled ?? true,
        hapticEnabled: hapticEnabled ?? true,
        analyticsEnabled: analyticsEnabled ?? true,
      );
    } catch (e) {
      // Use default settings if loading fails
      state = state.copyWith(id: 'app_settings');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(StorageKeys.language, state.language.code);
      await prefs.setString(StorageKeys.themeMode, state.themeMode.displayName);
      await prefs.setBool(
        StorageKeys.notificationsEnabled,
        state.notificationsEnabled,
      );
      await prefs.setBool(StorageKeys.soundEnabled, state.soundEnabled);
      await prefs.setBool(StorageKeys.hapticEnabled, state.hapticEnabled);
      await prefs.setBool(StorageKeys.analyticsEnabled, state.analyticsEnabled);
    } catch (e) {
      // Handle save error
    }
  }

  /// Update language
  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  /// Update theme mode
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    await _saveSettings();
  }

  /// Toggle sound
  Future<void> toggleSound() async {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    await _saveSettings();
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptic() async {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
    await _saveSettings();
  }

  /// Toggle analytics
  Future<void> toggleAnalytics() async {
    state = state.copyWith(analyticsEnabled: !state.analyticsEnabled);
    await _saveSettings();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    state = AppSettings(id: 'app_settings');
    await _saveSettings();
  }

  /// Clear all data (settings only, not conversations)
  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.language);
    await prefs.remove(StorageKeys.themeMode);
    await prefs.remove(StorageKeys.notificationsEnabled);
    await prefs.remove(StorageKeys.soundEnabled);
    await prefs.remove(StorageKeys.hapticEnabled);
    await prefs.remove(StorageKeys.analyticsEnabled);

    state = AppSettings(id: 'app_settings');
  }
}
