import '../platform_interface.dart';

/// Android platform implementation
///
/// Note: Currently using fallback implementation to avoid API compatibility issues
/// with third-party packages. Platform-specific implementations can be restored
/// after updating dependencies.
class AndroidPlatform extends FallbackPlatformInterface {
  AndroidPlatform._();

  static final AndroidPlatform _instance = AndroidPlatform._();

  factory AndroidPlatform() => _instance;
}

/// Get the Android platform implementation
PlatformInterface getAndroidPlatform() => AndroidPlatform();
