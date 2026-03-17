import '../platform_interface.dart';
import 'windows_camera_service.dart';
import 'windows_audio_service.dart';
import 'windows_file_service.dart';
import 'windows_notification_service.dart';
import 'windows_permissions.dart';

/// Windows platform implementation
class WindowsPlatform implements PlatformInterface {
  WindowsPlatform._();

  static final WindowsPlatform _instance = WindowsPlatform._();

  factory WindowsPlatform() => _instance;

  @override
  CameraService get camera => WindowsCameraService();

  @override
  AudioService get audio => WindowsAudioService();

  @override
  FileService get file => WindowsFileService();

  @override
  NotificationService get notification => WindowsNotificationService();

  @override
  PlatformPermissions get permissions => WindowsPermissions();
}

/// Get the Windows platform implementation
PlatformInterface getWindowsPlatform() => WindowsPlatform();
