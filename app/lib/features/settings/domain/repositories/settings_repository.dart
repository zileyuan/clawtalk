import '../../../core/errors/failures.dart';
import '../data/models/settings_model.dart';

/// Repository interface for app settings.
///
/// Follows the Repository pattern from Clean Architecture.
/// This is the contract that the data layer must implement.
abstract class SettingsRepository {
  /// Get the current settings.
  Future<({Failure? failure, SettingsModel? settings})> getSettings();

  /// Save settings.
  Future<Failure?> saveSettings(SettingsModel settings);

  /// Update the theme mode.
  Future<Failure?> setThemeMode(AppThemeMode themeMode);

  /// Update the locale.
  Future<Failure?> setLocale(String? locale);

  /// Update notification settings.
  Future<Failure?> setNotificationsEnabled(bool enabled);

  /// Update sound settings.
  Future<Failure?> setSoundEnabled(bool enabled);

  /// Update vibration settings.
  Future<Failure?> setVibrationEnabled(bool enabled);

  /// Update auto-reconnect settings.
  Future<Failure?> setAutoReconnect(bool enabled);

  /// Update message font size.
  Future<Failure?> setMessageFontSize(int size);

  /// Update show timestamps setting.
  Future<Failure?> setShowTimestamps(bool show);

  /// Update show connection status setting.
  Future<Failure?> setShowConnectionStatus(bool show);

  /// Update developer mode setting.
  Future<Failure?> setDeveloperMode(bool enabled);

  /// Reset all settings to defaults.
  Future<Failure?> resetSettings();
}
