class StorageKeys {
  StorageKeys._();

  static const String connections = 'clawtalk_connections';
  static const String settings = 'clawtalk_settings';
  static const String lastConnection = 'clawtalk_last_connection';
  static const String theme = 'clawtalk_theme';
  static const String locale = 'clawtalk_locale';
  static const String sessionHistory = 'clawtalk_session_history';

  // Settings keys
  static const String language = 'clawtalk_language';
  static const String themeMode = 'clawtalk_theme_mode';
  static const String notificationsEnabled = 'clawtalk_notifications_enabled';
  static const String soundEnabled = 'clawtalk_sound_enabled';
  static const String hapticEnabled = 'clawtalk_haptic_enabled';
  static const String analyticsEnabled = 'clawtalk_analytics_enabled';

  static String connectionToken(String connectionId) =>
      'clawtalk_token_$connectionId';

  static String connectionPassword(String connectionId) =>
      'clawtalk_password_$connectionId';
}
