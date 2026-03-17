import 'package:camera/camera.dart';

import '../platform_interface.dart';

/// macOS implementation of PlatformPermissions
/// Note: macOS handles permissions through Info.plist and system dialogs
class MacOSPermissions implements PlatformPermissions {
  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        return _checkCameraPermission();
      case PermissionType.microphone:
        return _checkMicrophonePermission();
      case PermissionType.storage:
        // macOS doesn't require explicit storage permission
        return PermissionStatus.granted;
      case PermissionType.notification:
        // macOS handles notification permission differently
        return PermissionStatus.granted;
    }
  }

  Future<PermissionStatus> _checkCameraPermission() async {
    try {
      final status = await CameraPlatform.instance.getCameraPermissionStatus();
      return _mapCameraPermissionStatus(status);
    } catch (e) {
      return PermissionStatus.notDetermined;
    }
  }

  Future<PermissionStatus> _checkMicrophonePermission() async {
    try {
      // For microphone, we check via the audio recorder package
      // The record package handles this internally
      return PermissionStatus.notDetermined;
    } catch (e) {
      return PermissionStatus.notDetermined;
    }
  }

  PermissionStatus _mapCameraPermissionStatus(CameraPermissionStatus status) {
    switch (status) {
      case CameraPermissionStatus.granted:
        return PermissionStatus.granted;
      case CameraPermissionStatus.denied:
        return PermissionStatus.denied;
      case CameraPermissionStatus.restricted:
        return PermissionStatus.restricted;
      default:
        return PermissionStatus.notDetermined;
    }
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        return _requestCameraPermission();
      case PermissionType.microphone:
        return _requestMicrophonePermission();
      case PermissionType.storage:
        // macOS doesn't require explicit storage permission
        return PermissionStatus.granted;
      case PermissionType.notification:
        // Notification permission is handled by NotificationService
        return PermissionStatus.granted;
    }
  }

  Future<PermissionStatus> _requestCameraPermission() async {
    try {
      final status = await CameraPlatform.instance.requestCameraPermission();
      return _mapCameraPermissionStatus(status);
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  Future<PermissionStatus> _requestMicrophonePermission() async {
    try {
      // The record package handles microphone permission
      // We return not determined since we can't directly request it here
      // The actual permission request happens when starting audio recording
      return PermissionStatus.notDetermined;
    } catch (e) {
      return PermissionStatus.denied;
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
