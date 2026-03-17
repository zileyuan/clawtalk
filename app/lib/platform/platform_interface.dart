import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';

/// Permission types that may be required by platform services
enum PermissionType { camera, microphone, storage, notification }

/// Permission status
enum PermissionStatus {
  granted,
  denied,
  restricted,
  limited,
  permanentlyDenied,
  notDetermined,
}

/// Camera description info
class CameraInfo {
  final String id;
  final String name;
  final bool isFrontFacing;
  final bool isBackFacing;

  const CameraInfo({
    required this.id,
    required this.name,
    this.isFrontFacing = false,
    this.isBackFacing = false,
  });
}

/// Audio recording configuration
class AudioConfig {
  final int sampleRate;
  final int channels;
  final AudioFormat format;
  final int bitRate;

  const AudioConfig({
    this.sampleRate = 44100,
    this.channels = 1,
    this.format = AudioFormat.aac,
    this.bitRate = 128000,
  });
}

/// Audio format types
enum AudioFormat { aac, mp3, wav, m4a, ogg }

/// Audio playback state
enum AudioPlaybackState { playing, paused, stopped, completed }

/// Notification options
class NotificationOptions {
  final String title;
  final String body;
  final String? subtitle;
  final String? sound;
  final int? badge;
  final Map<String, dynamic>? data;

  const NotificationOptions({
    required this.title,
    required this.body,
    this.subtitle,
    this.sound,
    this.badge,
    this.data,
  });
}

/// File metadata
class FileMetadata {
  final String name;
  final String path;
  final int size;
  final String? extension;
  final String? mimeType;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const FileMetadata({
    required this.name,
    required this.path,
    required this.size,
    this.extension,
    this.mimeType,
    this.createdAt,
    this.modifiedAt,
  });
}

/// File picker options
class FilePickerOptions {
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  final String? dialogTitle;
  final String? initialDirectory;

  const FilePickerOptions({
    this.allowedExtensions,
    this.allowMultiple = false,
    this.dialogTitle,
    this.initialDirectory,
  });
}

/// File save options
class FileSaveOptions {
  final String suggestedName;
  final List<String>? allowedExtensions;
  final String? dialogTitle;
  final String? initialDirectory;

  const FileSaveOptions({
    required this.suggestedName,
    this.allowedExtensions,
    this.dialogTitle,
    this.initialDirectory,
  });
}

/// Abstract interface for camera service
abstract class CameraService {
  /// Get available cameras
  Future<List<CameraInfo>> getAvailableCameras();

  /// Initialize camera with given ID
  Future<void> initialize(String cameraId);

  /// Start preview stream
  Future<void> startPreview();

  /// Stop preview stream
  Future<void> stopPreview();

  /// Capture image
  Future<Uint8List?> captureImage();

  /// Start video recording
  Future<void> startVideoRecording();

  /// Stop video recording and return file path
  Future<String?> stopVideoRecording();

  /// Dispose camera resources
  Future<void> dispose();

  /// Check if camera is initialized
  bool get isInitialized;

  /// Current camera ID
  String? get currentCameraId;
}

/// Abstract interface for audio service
abstract class AudioService {
  /// Check if recording is supported
  Future<bool> isRecordingSupported();

  /// Check if playback is supported
  Future<bool> isPlaybackSupported();

  /// Start recording with config
  Future<String?> startRecording({AudioConfig config = const AudioConfig()});

  /// Stop recording and return file path
  Future<String?> stopRecording();

  /// Pause recording
  Future<void> pauseRecording();

  /// Resume recording
  Future<void> resumeRecording();

  /// Check if currently recording
  bool get isRecording;

  /// Check if recording is paused
  bool get isPaused;

  /// Play audio from path
  Future<void> play(String path);

  /// Pause playback
  Future<void> pause();

  /// Resume playback
  Future<void> resume();

  /// Stop playback
  Future<void> stop();

  /// Set playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Get playback state stream
  Stream<AudioPlaybackState> get playbackStateStream;

  /// Get current playback state
  AudioPlaybackState get playbackState;

  /// Get recording amplitude stream (for visualization)
  Stream<double>? get amplitudeStream;

  /// Dispose resources
  Future<void> dispose();
}

/// Abstract interface for file service
abstract class FileService {
  /// Pick files using system picker
  Future<List<FileMetadata>> pickFiles(FilePickerOptions options);

  /// Pick single file
  Future<FileMetadata?> pickFile(FilePickerOptions options);

  /// Save file with data
  Future<String?> saveFile(FileSaveOptions options, Uint8List data);

  /// Read file data
  Future<Uint8List?> readFile(String path);

  /// Delete file
  Future<bool> deleteFile(String path);

  /// Check if file exists
  Future<bool> fileExists(String path);

  /// Get file metadata
  Future<FileMetadata?> getFileMetadata(String path);

  /// Get app documents directory
  Future<String> getDocumentsDirectory();

  /// Get app temporary directory
  Future<String> getTemporaryDirectory();

  /// Copy file
  Future<String?> copyFile(String sourcePath, String destinationPath);

  /// Move file
  Future<String?> moveFile(String sourcePath, String destinationPath);
}

/// Abstract interface for notification service
abstract class NotificationService {
  /// Initialize notification service
  Future<void> initialize();

  /// Show local notification
  Future<void> show(NotificationOptions options);

  /// Cancel notification by ID
  Future<void> cancel(int id);

  /// Cancel all notifications
  Future<void> cancelAll();

  /// Get pending notifications
  Future<List<NotificationOptions>> getPendingNotifications();

  /// Request notification permission
  Future<PermissionStatus> requestPermission();

  /// Check notification permission status
  Future<PermissionStatus> checkPermission();

  /// Dispose resources
  Future<void> dispose();
}

/// Abstract interface for platform permissions
abstract class PlatformPermissions {
  /// Check permission status
  Future<PermissionStatus> checkPermission(PermissionType type);

  /// Request permission
  Future<PermissionStatus> requestPermission(PermissionType type);

  /// Request multiple permissions
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> types,
  );

  /// Open app settings
  Future<bool> openAppSettings();

  /// Check if permission is permanently denied
  Future<bool> isPermanentlyDenied(PermissionType type);
}

/// Platform interface that aggregates all platform services
abstract class PlatformInterface {
  CameraService get camera;
  AudioService get audio;
  FileService get file;
  NotificationService get notification;
  PlatformPermissions get permissions;
}

/// Fallback implementation for unsupported platforms
class FallbackPlatformInterface implements PlatformInterface {
  @override
  CameraService get camera => _FallbackCameraService();

  @override
  AudioService get audio => _FallbackAudioService();

  @override
  FileService get file => _FallbackFileService();

  @override
  NotificationService get notification => _FallbackNotificationService();

  @override
  PlatformPermissions get permissions => _FallbackPermissions();
}

class _FallbackCameraService implements CameraService {
  @override
  Future<List<CameraInfo>> getAvailableCameras() async => [];

  @override
  Future<void> initialize(String cameraId) async {
    throw const MediaException(
      message: 'Camera not supported on this platform',
    );
  }

  @override
  Future<void> startPreview() async {}

  @override
  Future<void> stopPreview() async {}

  @override
  Future<Uint8List?> captureImage() async => null;

  @override
  Future<void> startVideoRecording() async {}

  @override
  Future<String?> stopVideoRecording() async => null;

  @override
  Future<void> dispose() async {}

  @override
  bool get isInitialized => false;

  @override
  String? get currentCameraId => null;
}

class _FallbackAudioService implements AudioService {
  @override
  Future<bool> isRecordingSupported() async => false;

  @override
  Future<bool> isPlaybackSupported() async => false;

  @override
  Future<String?> startRecording({
    AudioConfig config = const AudioConfig(),
  }) async {
    throw const MediaException(
      message: 'Audio recording not supported on this platform',
    );
  }

  @override
  Future<String?> stopRecording() async => null;

  @override
  Future<void> pauseRecording() async {}

  @override
  Future<void> resumeRecording() async {}

  @override
  bool get isRecording => false;

  @override
  bool get isPaused => false;

  @override
  Future<void> play(String path) async {
    throw const MediaException(
      message: 'Audio playback not supported on this platform',
    );
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Stream<AudioPlaybackState> get playbackStateStream =>
      Stream.value(AudioPlaybackState.stopped);

  @override
  AudioPlaybackState get playbackState => AudioPlaybackState.stopped;

  @override
  Stream<double>? get amplitudeStream => null;

  @override
  Future<void> dispose() async {}
}

class _FallbackFileService implements FileService {
  @override
  Future<List<FileMetadata>> pickFiles(FilePickerOptions options) async => [];

  @override
  Future<FileMetadata?> pickFile(FilePickerOptions options) async => null;

  @override
  Future<String?> saveFile(FileSaveOptions options, Uint8List data) async =>
      null;

  @override
  Future<Uint8List?> readFile(String path) async => null;

  @override
  Future<bool> deleteFile(String path) async => false;

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<FileMetadata?> getFileMetadata(String path) async => null;

  @override
  Future<String> getDocumentsDirectory() async => '';

  @override
  Future<String> getTemporaryDirectory() async => '';

  @override
  Future<String?> copyFile(String sourcePath, String destinationPath) async =>
      null;

  @override
  Future<String?> moveFile(String sourcePath, String destinationPath) async =>
      null;
}

class _FallbackNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(NotificationOptions options) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<List<NotificationOptions>> getPendingNotifications() async => [];

  @override
  Future<PermissionStatus> requestPermission() async => PermissionStatus.denied;

  @override
  Future<PermissionStatus> checkPermission() async => PermissionStatus.denied;

  @override
  Future<void> dispose() async {}
}

class _FallbackPermissions implements PlatformPermissions {
  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async =>
      PermissionStatus.denied;

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async =>
      PermissionStatus.denied;

  @override
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> types,
  ) async {
    return {for (final type in types) type: PermissionStatus.denied};
  }

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<bool> isPermanentlyDenied(PermissionType type) async => false;
}

/// Platform interface provider
final platformInterfaceProvider = Provider<PlatformInterface>((ref) {
  // This will be overridden in platform_provider.dart
  return FallbackPlatformInterface();
});

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
