import '../platform_interface.dart';
import 'android_camera_service.dart';
import 'android_audio_service.dart';
import 'android_file_service.dart';
import 'android_notification_service.dart';
import 'android_permissions.dart';

/// Android platform implementation
class AndroidPlatform implements PlatformInterface {
  AndroidPlatform._();

  static final AndroidPlatform _instance = AndroidPlatform._();

  factory AndroidPlatform() => _instance;

  @override
  CameraService get camera => AndroidCameraService();

  @override
  AudioService get audio => AndroidAudioService();

  @override
  FileService get file => AndroidFileService();

  @override
  NotificationService get notification => AndroidNotificationService();

  @override
  PlatformPermissions get permissions => AndroidPermissions();
}

/// Get the Android platform implementation
PlatformInterface getAndroidPlatform() => AndroidPlatform();
