import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_interface.dart';
import 'platform_utils.dart';

// Conditional imports for platform-specific implementations
import 'macos/macOS_platform.dart'
    if (dart.library.io) 'macos/macOS_platform.dart'
    as macos_platform;
import 'windows/windows_platform.dart'
    if (dart.library.io) 'windows/windows_platform.dart'
    as windows_platform;
import 'android/android_platform.dart'
    if (dart.library.io) 'android/android_platform.dart'
    as android_platform;
import 'ios/ios_platform.dart'
    if (dart.library.io) 'ios/ios_platform.dart'
    as ios_platform;

/// Platform interface implementation provider
/// Returns the correct platform implementation based on the current platform
final platformInterfaceProvider = Provider<PlatformInterface>((ref) {
  return _getPlatformImplementation();
});

/// Get the appropriate platform implementation
PlatformInterface _getPlatformImplementation() {
  try {
    if (PlatformUtils.isMacOS) {
      return macos_platform.getMacOSPlatform();
    } else if (PlatformUtils.isWindows) {
      return windows_platform.getWindowsPlatform();
    } else if (PlatformUtils.isAndroid) {
      return android_platform.getAndroidPlatform();
    } else if (PlatformUtils.isIOS) {
      return ios_platform.getIOSPlatform();
    } else {
      // Fallback for unsupported platforms (e.g., Linux, Web)
      return FallbackPlatformInterface();
    }
  } catch (e) {
    // Return fallback if platform detection fails
    return FallbackPlatformInterface();
  }
}

/// Camera service provider
final cameraServiceProvider = Provider<CameraService>((ref) {
  return ref.watch(platformInterfaceProvider).camera;
});

/// Audio service provider
final audioServiceProvider = Provider<AudioService>((ref) {
  return ref.watch(platformInterfaceProvider).audio;
});

/// File service provider
final fileServiceProvider = Provider<FileService>((ref) {
  return ref.watch(platformInterfaceProvider).file;
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return ref.watch(platformInterfaceProvider).notification;
});

/// Permissions provider
final permissionsProvider = Provider<PlatformPermissions>((ref) {
  return ref.watch(platformInterfaceProvider).permissions;
});

/// Check if camera is available on current platform
final isCameraAvailableProvider = Provider<bool>((ref) {
  return PlatformUtils.isCameraAvailable;
});

/// Check if microphone is available on current platform
final isMicrophoneAvailableProvider = Provider<bool>((ref) {
  return PlatformUtils.isMicrophoneAvailable;
});

/// Check if notifications are available on current platform
final isNotificationAvailableProvider = Provider<bool>((ref) {
  return PlatformUtils.isNotificationAvailable;
});

/// Check if file picker is available on current platform
final isFilePickerAvailableProvider = Provider<bool>((ref) {
  return PlatformUtils.isFilePickerAvailable;
});

/// Get platform name provider
final platformNameProvider = Provider<String>((ref) {
  return PlatformUtils.platformName;
});

/// Check if running on mobile provider
final isMobileProvider = Provider<bool>((ref) {
  return PlatformUtils.isMobile;
});

/// Check if running on desktop provider
final isDesktopProvider = Provider<bool>((ref) {
  return PlatformUtils.isDesktop;
});
