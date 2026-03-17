import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import '../platform_interface.dart';
import '../../core/errors/exceptions.dart';

/// macOS implementation of CameraService using camera package
class MacOSCameraService implements CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  String? _currentCameraId;
  bool _isInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;

  @override
  Future<List<CameraInfo>> getAvailableCameras() async {
    try {
      _cameras = await availableCameras();
      return _cameras
          .map(
            (camera) => CameraInfo(
              id: camera.name,
              name: camera.name,
              isFrontFacing: camera.lensDirection == CameraLensDirection.front,
              isBackFacing: camera.lensDirection == CameraLensDirection.back,
            ),
          )
          .toList();
    } catch (e) {
      throw MediaException(
        message: 'Failed to get available cameras: $e',
        code: 1001,
      );
    }
  }

  @override
  Future<void> initialize(String cameraId) async {
    try {
      // Find camera by ID
      final camera = _cameras.firstWhere(
        (c) => c.name == cameraId,
        orElse: () => _cameras.isNotEmpty
            ? _cameras.first
            : throw MediaException(
                message: 'Camera not found: $cameraId',
                code: 1002,
              ),
      );

      // Dispose existing controller
      await dispose();

      // Create new controller
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _currentCameraId = cameraId;
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      if (e is MediaException) rethrow;
      throw MediaException(
        message: 'Failed to initialize camera: $e',
        code: 1003,
      );
    }
  }

  @override
  Future<void> startPreview() async {
    if (!_isInitialized || _controller == null) {
      throw const MediaException(message: 'Camera not initialized', code: 1004);
    }

    try {
      await _controller!.startImageStream((image) {
        // Image stream for preview - handled by widget
      });
    } catch (e) {
      throw MediaException(message: 'Failed to start preview: $e', code: 1005);
    }
  }

  @override
  Future<void> stopPreview() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  @override
  Future<Uint8List?> captureImage() async {
    if (!_isInitialized || _controller == null) {
      throw const MediaException(message: 'Camera not initialized', code: 1004);
    }

    try {
      final image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      return bytes;
    } catch (e) {
      throw MediaException(message: 'Failed to capture image: $e', code: 1006);
    }
  }

  @override
  Future<void> startVideoRecording() async {
    if (!_isInitialized || _controller == null) {
      throw const MediaException(message: 'Camera not initialized', code: 1004);
    }

    if (_isRecording) {
      throw const MediaException(message: 'Already recording', code: 1007);
    }

    try {
      // Create temp file path
      final tempDir = await getTemporaryDirectory();
      _recordingPath =
          '${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _controller!.startVideoRecording();
      _isRecording = true;
    } catch (e) {
      throw MediaException(
        message: 'Failed to start video recording: $e',
        code: 1008,
      );
    }
  }

  @override
  Future<String?> stopVideoRecording() async {
    if (!_isRecording || _controller == null) {
      return null;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Move to our path
      if (_recordingPath != null && file.path != _recordingPath) {
        final newFile = await File(file.path).copy(_recordingPath!);
        await File(file.path).delete();
        return newFile.path;
      }

      return file.path;
    } catch (e) {
      _isRecording = false;
      throw MediaException(
        message: 'Failed to stop video recording: $e',
        code: 1009,
      );
    }
  }

  @override
  Future<void> dispose() async {
    await stopPreview();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _currentCameraId = null;
    _isRecording = false;
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  String? get currentCameraId => _currentCameraId;

  /// Get camera controller for widget use
  CameraController? get controller => _controller;
}
