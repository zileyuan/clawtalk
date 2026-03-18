import '../platform_interface.dart';

/// Windows platform implementation
///
/// Note: Currently using fallback implementation to avoid API compatibility issues
/// with third-party packages. Platform-specific implementations can be restored
/// after updating dependencies.
class WindowsPlatform extends FallbackPlatformInterface {
  WindowsPlatform._();

  static final WindowsPlatform _instance = WindowsPlatform._();

  factory WindowsPlatform() => _instance;
}

/// Get the Windows platform implementation
PlatformInterface getWindowsPlatform() => WindowsPlatform();
