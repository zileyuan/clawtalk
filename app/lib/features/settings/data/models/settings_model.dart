import 'dart:ui';
import 'package:flutter/material.dart';

/// Theme mode options for the app.
enum AppThemeMode {
  system,
  light,
  dark;

  String toJson() => name;

  static AppThemeMode fromJson(String value) {
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}

/// Data model for app settings with JSON serialization.
class SettingsModel {
  final AppThemeMode themeMode;
  final String? locale;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoReconnect;
  final int messageFontSize;
  final bool showTimestamps;
  final bool showConnectionStatus;
  final bool developerMode;

  const SettingsModel({
    this.themeMode = AppThemeMode.system,
    this.locale,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoReconnect = true,
    this.messageFontSize = 14,
    this.showTimestamps = true,
    this.showConnectionStatus = true,
    this.developerMode = false,
  });

  /// Create a model from a JSON map.
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      themeMode: json['themeMode'] != null
          ? AppThemeMode.fromJson(json['themeMode'] as String)
          : AppThemeMode.system,
      locale: json['locale'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      messageFontSize: json['messageFontSize'] as int? ?? 14,
      showTimestamps: json['showTimestamps'] as bool? ?? true,
      showConnectionStatus: json['showConnectionStatus'] as bool? ?? true,
      developerMode: json['developerMode'] as bool? ?? false,
    );
  }

  /// Convert the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.toJson(),
      'locale': locale,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'autoReconnect': autoReconnect,
      'messageFontSize': messageFontSize,
      'showTimestamps': showTimestamps,
      'showConnectionStatus': showConnectionStatus,
      'developerMode': developerMode,
    };
  }

  /// Create a copy with updated values.
  SettingsModel copyWith({
    AppThemeMode? themeMode,
    String? locale,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoReconnect,
    int? messageFontSize,
    bool? showTimestamps,
    bool? showConnectionStatus,
    bool? developerMode,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      messageFontSize: messageFontSize ?? this.messageFontSize,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      showConnectionStatus: showConnectionStatus ?? this.showConnectionStatus,
      developerMode: developerMode ?? this.developerMode,
    );
  }

  /// Get the Flutter ThemeMode from app settings.
  ThemeMode get flutterThemeMode {
    return switch (themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }

  /// Get the Locale from settings.
  Locale? get flutterLocale {
    if (locale == null) return null;
    final parts = locale!.split('_');
    if (parts.length == 1) {
      return Locale(parts[0]);
    } else if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return null;
  }

  /// Default settings.
  static const SettingsModel defaults = SettingsModel();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsModel &&
        other.themeMode == themeMode &&
        other.locale == locale &&
        other.notificationsEnabled == notificationsEnabled &&
        other.soundEnabled == soundEnabled &&
        other.vibrationEnabled == vibrationEnabled &&
        other.autoReconnect == autoReconnect &&
        other.messageFontSize == messageFontSize &&
        other.showTimestamps == showTimestamps &&
        other.showConnectionStatus == showConnectionStatus &&
        other.developerMode == developerMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      locale,
      notificationsEnabled,
      soundEnabled,
      vibrationEnabled,
      autoReconnect,
      messageFontSize,
      showTimestamps,
      showConnectionStatus,
      developerMode,
    );
  }

  @override
  String toString() {
    return 'SettingsModel(themeMode: $themeMode, locale: $locale, '
        'notificationsEnabled: $notificationsEnabled, soundEnabled: $soundEnabled)';
  }
}
