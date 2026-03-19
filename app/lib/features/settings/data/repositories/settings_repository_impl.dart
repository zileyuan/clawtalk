import 'package:clawtalk/core/errors/error_handler.dart';
import 'package:clawtalk/core/errors/exceptions.dart';
import 'package:clawtalk/core/errors/failures.dart';
import 'package:clawtalk/features/settings/data/datasources/local/settings_local_data_source.dart';
import 'package:clawtalk/features/settings/data/models/settings_model.dart';
import 'package:clawtalk/features/settings/domain/repositories/settings_repository.dart';

/// Implementation of [SettingsRepository].
///
/// Uses local data source for settings persistence.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl({required SettingsLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<({Failure? failure, SettingsModel? settings})> getSettings() async {
    try {
      final settings = await _localDataSource.getSettings();
      return (failure: null, settings: settings);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), settings: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to load settings: $e'),
        settings: null,
      );
    }
  }

  @override
  Future<Failure?> saveSettings(SettingsModel settings) async {
    try {
      await _localDataSource.saveSettings(settings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to save settings: $e');
    }
  }

  @override
  Future<Failure?> setThemeMode(AppThemeMode themeMode) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(themeMode: themeMode);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update theme mode: $e');
    }
  }

  @override
  Future<Failure?> setLocale(String? locale) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(locale: locale);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update locale: $e');
    }
  }

  @override
  Future<Failure?> setNotificationsEnabled(bool enabled) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(notificationsEnabled: enabled);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(
        message: 'Failed to update notifications setting: $e',
      );
    }
  }

  @override
  Future<Failure?> setSoundEnabled(bool enabled) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(soundEnabled: enabled);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update sound setting: $e');
    }
  }

  @override
  Future<Failure?> setVibrationEnabled(bool enabled) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(vibrationEnabled: enabled);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update vibration setting: $e');
    }
  }

  @override
  Future<Failure?> setAutoReconnect(bool enabled) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(autoReconnect: enabled);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(
        message: 'Failed to update auto-reconnect setting: $e',
      );
    }
  }

  @override
  Future<Failure?> setMessageFontSize(int size) async {
    try {
      // Validate font size
      if (size < 10 || size > 24) {
        return const ValidationFailure(
          message: 'Font size must be between 10 and 24',
        );
      }

      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(messageFontSize: size);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update message font size: $e');
    }
  }

  @override
  Future<Failure?> setShowTimestamps(bool show) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(showTimestamps: show);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update timestamps setting: $e');
    }
  }

  @override
  Future<Failure?> setShowConnectionStatus(bool show) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(showConnectionStatus: show);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(
        message: 'Failed to update connection status setting: $e',
      );
    }
  }

  @override
  Future<Failure?> setDeveloperMode(bool enabled) async {
    try {
      final settings = await _localDataSource.getSettings();
      final updatedSettings = settings.copyWith(developerMode: enabled);
      await _localDataSource.saveSettings(updatedSettings);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update developer mode: $e');
    }
  }

  @override
  Future<Failure?> resetSettings() async {
    try {
      await _localDataSource.resetSettings();
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to reset settings: $e');
    }
  }
}
