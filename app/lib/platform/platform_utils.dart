import 'dart:io' show Platform;

/// Platform detection utilities
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on macOS
  static bool get isMacOS => Platform.isMacOS;

  /// Check if running on Windows
  static bool get isWindows => Platform.isWindows;

  /// Check if running on Linux
  static bool get isLinux => Platform.isLinux;

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if running on a mobile platform (iOS or Android)
  static bool get isMobile => Platform.isIOS || Platform.isAndroid;

  /// Check if running on a desktop platform (macOS, Windows, or Linux)
  static bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// Check if running on Apple platform (macOS or iOS)
  static bool get isApple => Platform.isMacOS || Platform.isIOS;

  /// Get current platform name
  static String get platformName {
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }

  /// Get platform-specific path separator
  static String get pathSeparator => Platform.pathSeparator;

  /// Get the number of processors
  static int get numberOfProcessors => Platform.numberOfProcessors;

  /// Get operating system version
  static String get operatingSystemVersion => Platform.operatingSystemVersion;

  /// Get local hostname
  static String get localHostname => Platform.localHostname;

  /// Get environment variables
  static Map<String, String> get environment => Platform.environment;

  /// Get Dart version
  static String get dartVersion => Platform.version;

  /// Check if running in debug mode
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Check if running in release mode
  static bool get isReleaseMode => !isDebugMode;

  /// Get line terminator for current platform
  static String get lineTerminator {
    if (Platform.isWindows) return '\r\n';
    return '\n';
  }

  /// Check if camera is likely available on this platform
  static bool get isCameraAvailable {
    // All target platforms support camera
    return isMobile || isMacOS;
  }

  /// Check if microphone is likely available on this platform
  static bool get isMicrophoneAvailable {
    // All target platforms support microphone
    return true;
  }

  /// Check if local notifications are available on this platform
  static bool get isNotificationAvailable {
    // All target platforms support local notifications
    return true;
  }

  /// Check if file picker is available on this platform
  static bool get isFilePickerAvailable {
    // All target platforms support file picker
    return true;
  }

  /// Get platform-specific default audio format
  static String get defaultAudioFormat {
    if (Platform.isIOS || Platform.isMacOS) return 'm4a';
    if (Platform.isAndroid) return 'm4a';
    return 'mp3';
  }

  /// Get platform-specific default image format
  static String get defaultImageFormat {
    if (Platform.isIOS || Platform.isMacOS) return 'heic';
    return 'jpg';
  }

  /// Get platform-specific default video format
  static String get defaultVideoFormat {
    if (Platform.isIOS || Platform.isMacOS) return 'mov';
    return 'mp4';
  }
}

/// Platform-specific path utilities
class PlatformPaths {
  PlatformPaths._();

  /// Join path segments with proper separator
  static String join(List<String> parts) {
    return parts.join(Platform.pathSeparator);
  }

  /// Get file extension from path
  static String? getExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return null;
    return path.substring(lastDot + 1).toLowerCase();
  }

  /// Get file name from path (with extension)
  static String getFileName(String path) {
    final lastSeparator = path.lastIndexOf(Platform.pathSeparator);
    if (lastSeparator == -1) return path;
    return path.substring(lastSeparator + 1);
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String path) {
    final fileName = getFileName(path);
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return fileName;
    return fileName.substring(0, lastDot);
  }

  /// Get directory path from file path
  static String getDirectory(String path) {
    final lastSeparator = path.lastIndexOf(Platform.pathSeparator);
    if (lastSeparator == -1) return '';
    return path.substring(0, lastSeparator);
  }
}

/// Platform-specific mime type utilities
class PlatformMimeTypes {
  PlatformMimeTypes._();

  /// Audio mime types
  static const Map<String, String> audioMimeTypes = {
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'flac': 'audio/flac',
  };

  /// Image mime types
  static const Map<String, String> imageMimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'bmp': 'image/bmp',
  };

  /// Video mime types
  static const Map<String, String> videoMimeTypes = {
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
  };

  /// Get mime type from extension
  static String? getMimeType(String extension) {
    final ext = extension.toLowerCase();
    return audioMimeTypes[ext] ?? imageMimeTypes[ext] ?? videoMimeTypes[ext];
  }

  /// Check if extension is audio
  static bool isAudio(String extension) {
    return audioMimeTypes.containsKey(extension.toLowerCase());
  }

  /// Check if extension is image
  static bool isImage(String extension) {
    return imageMimeTypes.containsKey(extension.toLowerCase());
  }

  /// Check if extension is video
  static bool isVideo(String extension) {
    return videoMimeTypes.containsKey(extension.toLowerCase());
  }

  /// Check if extension is media (audio, image, or video)
  static bool isMedia(String extension) {
    final ext = extension.toLowerCase();
    return isAudio(ext) || isImage(ext) || isVideo(ext);
  }
}
