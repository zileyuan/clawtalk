import '../../../../core/constants/storage_keys.dart';
import '../../../../core/data/datasources/local/preferences_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/settings_model.dart';

/// Local data source for app settings.
///
/// Handles persistence of user preferences using preferences storage.
abstract class SettingsLocalDataSource {
  /// Get the current settings.
  Future<SettingsModel> getSettings();

  /// Save settings.
  Future<void> saveSettings(SettingsModel settings);

  /// Update a specific setting.
  Future<void> updateSetting(String key, dynamic value);

  /// Reset settings to defaults.
  Future<void> resetSettings();
}

/// Implementation of [SettingsLocalDataSource] using preferences.
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final PreferencesService _preferences;

  SettingsLocalDataSourceImpl({required PreferencesService preferences})
    : _preferences = preferences;

  @override
  Future<SettingsModel> getSettings() async {
    try {
      final json = _preferences.readJson(StorageKeys.settings);
      if (json == null) {
        return SettingsModel.defaults;
      }
      return SettingsModel.fromJson(json);
    } catch (e) {
      throw CacheException(message: 'Failed to load settings: $e', code: 1);
    }
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    try {
      await _preferences.writeJson(StorageKeys.settings, settings.toJson());

      // Also save theme and locale separately for easy access
      await _preferences.writeString(
        StorageKeys.theme,
        settings.themeMode.toJson(),
      );

      if (settings.locale != null) {
        await _preferences.writeString(StorageKeys.locale, settings.locale!);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to save settings: $e', code: 2);
    }
  }

  @override
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      final settings = await getSettings();
      final json = settings.toJson();
      json[key] = value;
      await _preferences.writeJson(StorageKeys.settings, json);
    } catch (e) {
      throw CacheException(message: 'Failed to update setting: $e', code: 3);
    }
  }

  @override
  Future<void> resetSettings() async {
    try {
      await saveSettings(SettingsModel.defaults);
    } catch (e) {
      throw CacheException(message: 'Failed to reset settings: $e', code: 4);
    }
  }
}
