import 'package:permission_handler/permission_handler.dart' as ph;

import '../platform_interface.dart';

/// Android implementation of PlatformPermissions
/// Handles Android 13+ permission model with granular permissions
class AndroidPermissions implements PlatformPermissions {
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
        // Android 13+ uses granular media permissions
        // For backwards compatibility, we check both
        return ph.Permission.photos;
      case PermissionType.notification:
        return ph.Permission.notification;
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

/// Required AndroidManifest.xml permissions:
///
/// ```xml
/// <!-- Camera -->
/// <uses-permission android:name="android.permission.CAMERA" />
/// <uses-feature android:name="android.hardware.camera" android:required="false" />
/// <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
///
/// <!-- Microphone -->
/// <uses-permission android:name="android.permission.RECORD_AUDIO" />
///
/// <!-- Storage (Android 12 and below) -->
/// <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
/// <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
///
/// <!-- Media (Android 13+) -->
/// <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
/// <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
/// <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
///
/// <!-- Notifications (Android 13+) -->
/// <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
///
/// <!-- Internet -->
/// <uses-permission android:name="android.permission.INTERNET" />
/// <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
/// ```
///
/// For Android 13+ (API 33+), add to build.gradle:
/// ```gradle
/// android {
///   compileSdkVersion 33
///   defaultConfig {
///     targetSdkVersion 33
///   }
/// }
/// ```
