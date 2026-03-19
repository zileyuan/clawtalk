import 'package:permission_handler/permission_handler.dart' as ph;

import '../platform_interface.dart';

/// iOS implementation of PlatformPermissions
class IOSPermissions implements PlatformPermissions {
  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    final permission = _mapPermissionType(type);
    if (permission == null) return PermissionStatus.granted;

    final status = await permission.status;
    return _mapPermissionStatus(status);
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    final permission = _mapPermissionType(type);
    if (permission == null) return PermissionStatus.granted;

    final status = await permission.request();
    return _mapPermissionStatus(status);
  }

  ph.Permission? _mapPermissionType(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return ph.Permission.camera;
      case PermissionType.microphone:
        return ph.Permission.microphone;
      case PermissionType.storage:
        // iOS doesn't have general storage permission
        // Photo library access is handled separately
        return ph.Permission.photos;
      case PermissionType.notification:
        // iOS notification permission is handled by NotificationService
        return null;
    }
  }

  PermissionStatus _mapPermissionStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case ph.PermissionStatus.limited:
        return PermissionStatus.limited;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.provisional:
        return PermissionStatus.limited;
    }
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> types,
  ) async {
    final permissions = <ph.Permission>[];

    for (final type in types) {
      final permission = _mapPermissionType(type);
      if (permission != null) {
        permissions.add(permission);
      }
    }

    final results = await permissions.request();

    final mappedResults = <PermissionType, PermissionStatus>{};
    for (final type in types) {
      final permission = _mapPermissionType(type);
      if (permission != null) {
        mappedResults[type] = _mapPermissionStatus(results[permission]!);
      } else {
        mappedResults[type] = PermissionStatus.granted;
      }
    }

    return mappedResults;
  }

  @override
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }

  @override
  Future<bool> isPermanentlyDenied(PermissionType type) async {
    final permission = _mapPermissionType(type);
    if (permission == null) return false;

    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}

/// Required Info.plist keys for iOS:
///
/// ```xml
/// <!-- Camera -->
/// <key>NSCameraUsageDescription</key>
/// <string>This app needs camera access to capture photos and videos.</string>
///
/// <!-- Microphone -->
/// <key>NSMicrophoneUsageDescription</key>
/// <string>This app needs microphone access to record audio.</string>
///
/// <!-- Photo Library (Read) -->
/// <key>NSPhotoLibraryUsageDescription</key>
/// <string>This app needs access to your photo library to select photos.</string>
///
/// <!-- Photo Library (Write) - iOS 11+ -->
/// <key>NSPhotoLibraryAddUsageDescription</key>
/// <string>This app needs permission to save photos to your photo library.</string>
///
/// <!-- Bluetooth (if needed) -->
/// <key>NSBluetoothAlwaysUsageDescription</key>
/// <string>This app needs Bluetooth access for nearby device communication.</string>
/// <key>NSBluetoothPeripheralUsageDescription</key>
/// <string>This app needs Bluetooth peripheral access.</string>
/// ```
///
/// Add these to your ios/Runner/Info.plist file.
///
/// For background audio, add to Info.plist:
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array>
///   <string>audio</string>
/// </array>
/// ```
