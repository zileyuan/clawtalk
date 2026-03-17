import '../platform_interface.dart';

/// Windows implementation of PlatformPermissions
/// Note: Windows handles permissions differently than mobile platforms
class WindowsPermissions implements PlatformPermissions {
  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        // Windows camera permission - typically granted at system level
        return PermissionStatus.granted;
      case PermissionType.microphone:
        // Windows microphone permission - typically granted at system level
        return PermissionStatus.granted;
      case PermissionType.storage:
        // Windows file system access - typically granted
        return PermissionStatus.granted;
      case PermissionType.notification:
        // Windows notification permission
        return PermissionStatus.granted;
    }
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    // Windows typically handles permissions at the system level
    // Apps don't need to request runtime permissions like mobile platforms
    return PermissionStatus.granted;
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
    // Windows doesn't have a standard app settings API
    // Users need to go to Settings > Privacy manually
    return false;
  }

  @override
  Future<bool> isPermanentlyDenied(PermissionType type) async {
    // Windows doesn't have permanently denied permissions
    return false;
  }
}

/// Windows-specific permission notes:
///
/// Windows handles most permissions at the system level through:
/// - Settings > Privacy > Camera
/// - Settings > Privacy > Microphone
///
/// Unlike mobile platforms, Windows apps typically don't need to request
/// runtime permissions programmatically. The system will prompt the user
/// when the app first attempts to access protected resources.
///
/// For file system access, Windows uses the file picker dialog which
/// automatically grants access to selected files/folders.
