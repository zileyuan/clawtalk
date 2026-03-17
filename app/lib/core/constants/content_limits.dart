class ContentLimits {
  ContentLimits._();

  static const int maxTextLength = 100000;
  static const int maxTextLines = 1000;
  static const int maxImageCount = 10;
  static const int maxImageSizeBytes = 10 * 1024 * 1024;
  static const int maxImageWidth = 4096;
  static const int maxImageHeight = 4096;
  static const int maxVoiceDurationSeconds = 300;
  static const int maxVoiceSizeBytes = 25 * 1024 * 1024;
  static const int maxFileNameLength = 255;

  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
    'heif',
  ];

  static const List<String> supportedAudioFormats = [
    'aac',
    'm4a',
    'wav',
    'mp3',
    'ogg',
    'opus',
  ];

  static bool isValidImageFormat(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    return supportedImageFormats.contains(ext);
  }

  static bool isValidAudioFormat(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    return supportedAudioFormats.contains(ext);
  }
}
