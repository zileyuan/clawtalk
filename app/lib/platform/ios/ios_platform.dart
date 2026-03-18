import '../platform_interface.dart';

/// iOS platform implementation
///
/// Note: Currently using fallback implementation to avoid API compatibility issues
/// with third-party packages. Platform-specific implementations can be restored
/// after updating dependencies.
class IOSPlatform extends FallbackPlatformInterface {
  IOSPlatform._();

  static final IOSPlatform _instance = IOSPlatform._();

  factory IOSPlatform() => _instance;
}

/// Get the iOS platform implementation
PlatformInterface getIOSPlatform() => IOSPlatform();
