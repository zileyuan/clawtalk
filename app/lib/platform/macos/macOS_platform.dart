import '../platform_interface.dart';

/// macOS platform implementation
///
/// Note: Currently using fallback implementation to avoid API compatibility issues
/// with third-party packages. Platform-specific implementations can be restored
/// after updating dependencies.
class MacOSPlatform extends FallbackPlatformInterface {
  MacOSPlatform._();

  static final MacOSPlatform _instance = MacOSPlatform._();

  factory MacOSPlatform() => _instance;
}

/// Get the macOS platform implementation
PlatformInterface getMacOSPlatform() => MacOSPlatform();
