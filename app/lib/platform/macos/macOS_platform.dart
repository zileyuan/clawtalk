import '../platform_interface.dart';
import 'macos_camera_service.dart';
import 'macos_audio_service.dart';
import 'macos_file_service.dart';
import 'macos_notification_service.dart';
import 'macos_permissions.dart';

/// macOS platform implementation
class MacOSPlatform implements PlatformInterface {
  MacOSPlatform._();

  static final MacOSPlatform _instance = MacOSPlatform._();

  factory MacOSPlatform() => _instance;

  @override
  CameraService get camera => MacOSCameraService();

  @override
  AudioService get audio => MacOSAudioService();

  @override
  FileService get file => MacOSFileService();

  @override
  NotificationService get notification => MacOSNotificationService();

  @override
  PlatformPermissions get permissions => MacOSPermissions();
}

/// Get the macOS platform implementation
PlatformInterface getMacOSPlatform() => MacOSPlatform();
