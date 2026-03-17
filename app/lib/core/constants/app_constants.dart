class AppConstants {
  AppConstants._();

  static const String appName = 'ClawTalk';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'OpenClaw Cross-platform Client';

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;

  static const int maxMessageLength = 100000;
  static const int maxImageCount = 10;
  static const int maxImageSizeMB = 10;
  static const int maxVoiceDurationSeconds = 300;
  static const int maxVoiceSizeMB = 25;
}
