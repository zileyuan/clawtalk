import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../platform_interface.dart';
import '../../core/errors/exceptions.dart';

/// macOS implementation of AudioService using record and audioplayers packages
class MacOSAudioService implements AudioService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;

  final StreamController<AudioPlaybackState> _playbackStateController =
      StreamController<AudioPlaybackState>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  AudioPlaybackState _playbackState = AudioPlaybackState.stopped;

  @override
  Future<bool> isRecordingSupported() async {
    return await _audioRecorder.hasPermission();
  }

  @override
  Future<bool> isPlaybackSupported() async {
    return true;
  }

  @override
  Future<String?> startRecording({
    AudioConfig config = const AudioConfig(),
  }) async {
    if (_isRecording) {
      throw const MediaException(message: 'Already recording', code: 2001);
    }

    try {
      // Check permission
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw const MediaException(
          message: 'Microphone permission not granted',
          code: 2002,
        );
      }

      // Create recording path
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Configure recording
      final recordConfig = RecordConfig(
        encoder: _getAudioEncoder(config.format),
        sampleRate: config.sampleRate,
        numChannels: config.channels,
        bitRate: config.bitRate,
      );

      await _audioRecorder.start(recordConfig, path: _currentRecordingPath!);
      _isRecording = true;
      _isPaused = false;

      // Start amplitude monitoring
      _startAmplitudeMonitoring();

      return _currentRecordingPath;
    } catch (e) {
      if (e is MediaException) rethrow;
      throw MediaException(
        message: 'Failed to start recording: $e',
        code: 2003,
      );
    }
  }

  AudioEncoder _getAudioEncoder(AudioFormat format) {
    switch (format) {
      case AudioFormat.aac:
        return AudioEncoder.aacLc;
      case AudioFormat.mp3:
        return AudioEncoder.mp3;
      case AudioFormat.wav:
        return AudioEncoder.wav;
      case AudioFormat.m4a:
        return AudioEncoder.aacLc;
      case AudioFormat.ogg:
        return AudioEncoder.opus;
    }
  }

  void _startAmplitudeMonitoring() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      try {
        final amplitude = await _audioRecorder.getAmplitude();
        _amplitudeController.add(amplitude.current);
      } catch (e) {
        // Ignore amplitude errors
      }
    });
  }

  @override
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      _isPaused = false;
      return path;
    } catch (e) {
      _isRecording = false;
      _isPaused = false;
      throw MediaException(message: 'Failed to stop recording: $e', code: 2004);
    }
  }

  @override
  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) return;

    try {
      await _audioRecorder.pause();
      _isPaused = true;
    } catch (e) {
      throw MediaException(
        message: 'Failed to pause recording: $e',
        code: 2005,
      );
    }
  }

  @override
  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;

    try {
      await _audioRecorder.resume();
      _isPaused = false;
    } catch (e) {
      throw MediaException(
        message: 'Failed to resume recording: $e',
        code: 2006,
      );
    }
  }

  @override
  bool get isRecording => _isRecording;

  @override
  bool get isPaused => _isPaused;

  @override
  Future<void> play(String path) async {
    try {
      // Check if file exists
      final file = File(path);
      if (!await file.exists()) {
        throw const MediaException(message: 'Audio file not found', code: 2007);
      }

      // Stop any current playback
      await stop();

      // Set up event listeners
      _audioPlayer.onPlayerStateChanged.listen((state) {
        _updatePlaybackState(state);
      });

      // Start playback
      await _audioPlayer.play(DeviceFileSource(path));
      _setPlaybackState(AudioPlaybackState.playing);
    } catch (e) {
      if (e is MediaException) rethrow;
      throw MediaException(message: 'Failed to play audio: $e', code: 2008);
    }
  }

  void _updatePlaybackState(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.idle:
        _setPlaybackState(AudioPlaybackState.stopped);
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
      case ProcessingState.ready:
        // Do nothing for these states
        break;
      case ProcessingState.completed:
        _setPlaybackState(AudioPlaybackState.completed);
        break;
    }
  }

  void _setPlaybackState(AudioPlaybackState state) {
    _playbackState = state;
    _playbackStateController.add(state);
  }

  @override
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _setPlaybackState(AudioPlaybackState.paused);
    } catch (e) {
      throw MediaException(message: 'Failed to pause audio: $e', code: 2009);
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      _setPlaybackState(AudioPlaybackState.playing);
    } catch (e) {
      throw MediaException(message: 'Failed to resume audio: $e', code: 2010);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _setPlaybackState(AudioPlaybackState.stopped);
    } catch (e) {
      throw MediaException(message: 'Failed to stop audio: $e', code: 2011);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      throw MediaException(message: 'Failed to set volume: $e', code: 2012);
    }
  }

  @override
  Stream<AudioPlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  @override
  AudioPlaybackState get playbackState => _playbackState;

  @override
  Stream<double>? get amplitudeStream => _amplitudeController.stream;

  @override
  Future<void> dispose() async {
    await stop();
    await _audioRecorder.dispose();
    await _audioPlayer.dispose();
    await _playbackStateController.close();
    await _amplitudeController.close();
  }
}
