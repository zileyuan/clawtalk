import '../platform_interface.dart';

/// macOS implementation of PlatformPermissions
/// Note: macOS handles permissions through Info.plist and system dialogs
class MacOSPermissions implements PlatformPermissions {
  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        // Camera permission is handled by the camera package when used
        // We return notDetermined to indicate we need to check at use time
        return PermissionStatus.notDetermined;
      case PermissionType.microphone:
        // Microphone permission is handled by the record package when used
        return PermissionStatus.notDetermined;
      case PermissionType.storage:
        // macOS doesn't require explicit storage permission
        return PermissionStatus.granted;
      case PermissionType.notification:
        // macOS handles notification permission differently
        return PermissionStatus.granted;
    }
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        // Camera permission is requested by the camera package when used
        // We return notDetermined to indicate the app should request when needed
        return PermissionStatus.notDetermined;
      case PermissionType.microphone:
        // Microphone permission is requested by the record package when used
        return PermissionStatus.notDetermined;
      case PermissionType.storage:
        // macOS doesn't require explicit storage permission
        return PermissionStatus.granted;
      case PermissionType.notification:
        // Notification permission is handled by NotificationService
        return PermissionStatus.granted;
    }
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> types,
  ) async {
    final results = <PermissionType, PermissionStatus>{};

    for (final type in types) {
      results[type] = await requestPermission(type);
    }

    return results;
  }

  @override
  Future<bool> openAppSettings() async {
    // macOS doesn't have a standard way to open app settings
    // Users need to go to System Preferences > Privacy & Security
    return false;
  }

  @override
  Future<bool> isPermanentlyDenied(PermissionType type) async {
    final status = await checkPermission(type);
    return status == PermissionStatus.denied;
  }
}

/// Required Info.plist keys for macOS:
///
/// <key>NSCameraUsageDescription</key>
/// <string>This app needs camera access to capture photos and videos.</string>
///
/// <key>NSMicrophoneUsageDescription</key>
/// <string>This app needs microphone access to record audio.</string>
///
/// Add these to your macos/Runner/Info.plist file.
