import '../platform_interface.dart';
import 'ios_camera_service.dart';
import 'ios_audio_service.dart';
import 'ios_file_service.dart';
import 'ios_notification_service.dart';
import 'ios_permissions.dart';

/// iOS platform implementation
class IOSPlatform implements PlatformInterface {
  IOSPlatform._();

  static final IOSPlatform _instance = IOSPlatform._();

  factory IOSPlatform() => _instance;

  @override
  CameraService get camera => IOSCameraService();

  @override
  AudioService get audio => IOSAudioService();

  @override
  FileService get file => IOSFileService();

  @override
  NotificationService get notification => IOSNotificationService();

  @override
  PlatformPermissions get permissions => IOSPermissions();
}

/// Get the iOS platform implementation
PlatformInterface getIOSPlatform() => IOSPlatform();
