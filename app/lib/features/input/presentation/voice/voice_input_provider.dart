import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/voice_input.dart';
import '../../../../core/constants/content_limits.dart';
import '../../../../core/utils/logger.dart';

/// Enum representing voice recording state
enum RecordingState { idle, recording, paused, stopping, error }

/// State class for voice input
class VoiceInputState {
  /// Current recording state
  final RecordingState recordingState;

  /// The recorded voice input (if complete)
  final VoiceInput? voiceInput;

  /// Current recording duration
  final Duration duration;

  /// Whether an operation is in progress
  final bool isLoading;

  /// Current error message if any
  final String? errorMessage;

  /// Recording amplitude values for waveform
  final List<double> amplitudes;

  /// Recording file path (while recording)
  final String? recordingPath;

  const VoiceInputState({
    this.recordingState = RecordingState.idle,
    this.voiceInput,
    this.duration = Duration.zero,
    this.isLoading = false,
    this.errorMessage,
    this.amplitudes = const [],
    this.recordingPath,
  });

  /// Factory constructor for idle state
  factory VoiceInputState.idle() {
    return const VoiceInputState();
  }

  /// Returns true if currently recording
  bool get isRecording => recordingState == RecordingState.recording;

  /// Returns true if recording is paused
  bool get isPaused => recordingState == RecordingState.paused;

  /// Returns true if has a recorded voice
  bool get hasRecording => voiceInput != null;

  /// Returns true if can start recording
  bool get canRecord =>
      recordingState == RecordingState.idle ||
      recordingState == RecordingState.error;

  /// Returns formatted duration string
  String get formattedDuration {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Returns true if duration is valid
  bool get hasValidDuration {
    return duration.inSeconds > 0 &&
        duration.inSeconds <= ContentLimits.maxVoiceDurationSeconds;
  }

  VoiceInputState copyWith({
    RecordingState? recordingState,
    VoiceInput? voiceInput,
    Duration? duration,
    bool? isLoading,
    String? errorMessage,
    List<double>? amplitudes,
    String? recordingPath,
    bool clearVoiceInput = false,
    bool clearError = false,
  }) {
    return VoiceInputState(
      recordingState: recordingState ?? this.recordingState,
      voiceInput: clearVoiceInput ? null : (voiceInput ?? this.voiceInput),
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      amplitudes: amplitudes ?? this.amplitudes,
      recordingPath: recordingPath ?? this.recordingPath,
    );
  }
}

/// Notifier for voice input state management
class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  DateTime? _recordingStartTime;
  StreamSubscription? _amplitudeSubscription;

  VoiceInputNotifier() : super(VoiceInputState.idle()) {
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      // Check initial permission status
      await _recorder.hasPermission();
    } catch (e) {
      Logger.error('Error initializing recorder: $e');
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording
  Future<void> startRecording() async {
    if (state.isRecording) return;

    try {
      // Check permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _setError('Microphone permission denied');
        return;
      }

      _setLoading(true);

      // Create recording file path
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recordingPath = '${dir.path}/voice_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: recordingPath,
      );

      _recordingStartTime = DateTime.now();

      state = state.copyWith(
        recordingState: RecordingState.recording,
        recordingPath: recordingPath,
        duration: Duration.zero,
        amplitudes: [],
        clearError: true,
      );

      _startTimer();
      _startAmplitudeMonitoring();
    } catch (e) {
      Logger.error('Error starting recording: $e');
      _setError('Failed to start recording: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!state.isRecording && !state.isPaused) return;

    _timer?.cancel();
    _amplitudeSubscription?.cancel();

    try {
      state = state.copyWith(recordingState: RecordingState.stopping);

      final path = await _recorder.stop();

      if (path != null) {
        final file = File(path);
        final fileStat = await file.stat();

        // Validate duration
        if (state.duration.inSeconds < 1) {
          await file.delete(ignore: true);
          _setError('Recording too short (minimum 1 second)');
          state = state.copyWith(
            recordingState: RecordingState.error,
            clearVoiceInput: true,
          );
          return;
        }

        // Validate size
        if (fileStat.size > ContentLimits.maxVoiceSizeBytes) {
          await file.delete(ignore: true);
          _setError(
            'Recording too large (maximum ${ContentLimits.maxVoiceSizeBytes ~/ (1024 * 1024)}MB)',
          );
          state = state.copyWith(
            recordingState: RecordingState.error,
            clearVoiceInput: true,
          );
          return;
        }

        // Create VoiceInput entity
        final voiceInput = VoiceInput(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: path,
          sizeBytes: fileStat.size,
          duration: state.duration,
          format: 'm4a',
          waveform: state.amplitudes.isNotEmpty
              ? state.amplitudes.join(',')
              : null,
        );

        state = state.copyWith(
          recordingState: RecordingState.idle,
          voiceInput: voiceInput,
          recordingPath: null,
        );
      }
    } catch (e) {
      Logger.error('Error stopping recording: $e');
      _setError('Failed to stop recording: $e');
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    if (!state.isRecording && !state.isPaused) return;

    _timer?.cancel();
    _amplitudeSubscription?.cancel();

    try {
      final path = await _recorder.stop();

      // Delete the recording file
      if (path != null) {
        await File(path).delete(ignore: true);
      }

      state = VoiceInputState.idle();
    } catch (e) {
      Logger.error('Error cancelling recording: $e');
    }
  }

  /// Clear the current recording
  Future<void> clearRecording() async {
    if (state.voiceInput != null) {
      try {
        final file = File(state.voiceInput!.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        Logger.error('Error deleting recording file: $e');
      }
    }

    state = VoiceInputState.idle();
  }

  /// Validate the recording
  bool validate() {
    if (state.voiceInput == null) {
      _setError('No recording available');
      return false;
    }

    if (!state.voiceInput!.hasValidDuration) {
      _setError('Invalid recording duration');
      return false;
    }

    if (!state.voiceInput!.hasValidSize) {
      _setError('Recording file too large');
      return false;
    }

    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime == null) return;

      final now = DateTime.now();
      final duration = now.difference(_recordingStartTime!);

      // Check max duration
      if (duration.inSeconds >= ContentLimits.maxVoiceDurationSeconds) {
        stopRecording();
        return;
      }

      state = state.copyWith(duration: duration);
    });
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    // Note: Real amplitude monitoring would use the recorder's amplitude stream
    // For now, we'll add placeholder amplitudes
    _amplitudeSubscription = Stream.periodic(const Duration(milliseconds: 50))
        .listen((_) async {
          try {
            final amplitude = await _recorder.getAmplitude();
            final newAmplitudes = [...state.amplitudes, amplitude.current];
            if (newAmplitudes.length > 200) {
              newAmplitudes.removeAt(0);
            }
            state = state.copyWith(amplitudes: newAmplitudes);
          } catch (e) {
            // Ignore amplitude errors
          }
        });
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String message) {
    state = state.copyWith(
      errorMessage: message,
      recordingState: RecordingState.error,
    );
  }

  /// Get the current voice input
  VoiceInput? get voiceInput => state.voiceInput;

  /// Check if recording is valid
  bool get isValid => state.hasRecording && state.hasValidDuration;

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

/// Provider for voice input state
final voiceInputProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>(
      (ref) => VoiceInputNotifier(),
    );

/// Provider for recording state
final recordingStateProvider = Provider<RecordingState>((ref) {
  return ref.watch(voiceInputProvider).recordingState;
});

/// Provider for voice input
final voiceInputEntityProvider = Provider<VoiceInput?>((ref) {
  return ref.watch(voiceInputProvider).voiceInput;
});

/// Provider for recording duration
final recordingDurationProvider = Provider<Duration>((ref) {
  return ref.watch(voiceInputProvider).duration;
});

/// Provider for formatted recording duration
final formattedDurationProvider = Provider<String>((ref) {
  return ref.watch(voiceInputProvider).formattedDuration;
});

/// Provider for amplitudes (for waveform)
final amplitudesProvider = Provider<List<double>>((ref) {
  return ref.watch(voiceInputProvider).amplitudes;
});

/// Provider for voice validation status
final voiceValidationProvider = Provider<bool>((ref) {
  return ref.watch(voiceInputProvider).isValid;
});
