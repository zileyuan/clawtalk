import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/constants/content_limits.dart';
import '../../../../core/utils/logger.dart' as log;
import 'voice_waveform.dart';

/// Voice recorder widget with press-and-hold recording button,
/// recording timer, and cancel gesture support
class VoiceRecorderWidget extends StatefulWidget {
  /// Callback when recording is complete
  final ValueChanged<String>? onRecordingComplete;

  /// Callback when recording is cancelled
  final VoidCallback? onRecordingCancelled;

  /// Maximum recording duration
  final Duration maxDuration;

  /// Minimum recording duration to be considered valid
  final Duration minDuration;

  /// Whether to show waveform visualization
  final bool showWaveform;

  /// Whether to enable haptic feedback
  final bool enableHapticFeedback;

  const VoiceRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.onRecordingCancelled,
    this.maxDuration = const Duration(seconds: 300),
    this.minDuration = const Duration(seconds: 1),
    this.showWaveform = true,
    this.enableHapticFeedback = true,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isLocked = false;
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String? _recordingPath;
  double _dragOffset = 0;
  final List<double> _amplitudes = [];

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog();
        return;
      }

      // Create recording file path
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${dir.path}/voice_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _recordingDuration = Duration.zero;
        _amplitudes.clear();
        _dragOffset = 0;
      });

      _startTimer();
    } catch (e) {
      log.logger.e('Error starting recording: $e');
      _showError('Failed to start recording');
    }
  }

  Future<void> _stopRecording({bool cancelled = false}) async {
    _timer?.cancel();

    try {
      final path = await _recorder.stop();

      setState(() {
        _isRecording = false;
        _isLocked = false;
        _dragOffset = 0;
      });

      if (!cancelled &&
          path != null &&
          _recordingDuration >= widget.minDuration) {
        widget.onRecordingComplete?.call(path);
      } else {
        // Delete the recording file if cancelled or too short
        if (path != null) {
          await File(path).delete();
        }
        widget.onRecordingCancelled?.call();
      }
    } catch (e) {
      log.logger.e('Error stopping recording: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_recordingStartTime == null) return;

      final now = DateTime.now();
      final duration = now.difference(_recordingStartTime!);

      // Update amplitudes for waveform
      if (_isRecording && widget.showWaveform) {
        _updateAmplitude();
      }

      // Check max duration
      if (duration >= widget.maxDuration) {
        _stopRecording();
        return;
      }

      setState(() {
        _recordingDuration = duration;
      });
    });
  }

  Future<void> _updateAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      setState(() {
        _amplitudes.add(amplitude.current);
        if (_amplitudes.length > 100) {
          _amplitudes.removeAt(0);
        }
      });
    } catch (e) {
      // Ignore amplitude errors
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isRecording || _isLocked) return;

    setState(() {
      _dragOffset += details.delta.dx;
    });

    // Cancel if dragged left enough
    if (_dragOffset < -100) {
      _stopRecording(cancelled: true);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;

    // Lock recording if dragged up
    if (details.delta.dy < -50 && !_isLocked) {
      setState(() {
        _isLocked = true;
        _dragOffset = 0;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Microphone Access Required'),
        content: const Text(
          'Please grant microphone permission to record voice messages.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(context);
              // Open app settings
            },
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((duration.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording) _buildRecordingInterface() else _buildRecordButton(),
      ],
    );
  }

  Widget _buildRecordButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _startRecording,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Icon(
          CupertinoIcons.mic_fill,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildRecordingInterface() {
    final showCancelHint = _dragOffset > -50 && !_isLocked;
    final isNearMax =
        _recordingDuration >= widget.maxDuration - const Duration(seconds: 10);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNearMax
            ? AppColors.error.withAlpha(26)
            : CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNearMax ? AppColors.error : AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordingDuration),
                style: AppTextStyles.headline2.copyWith(
                  color: isNearMax ? AppColors.error : CupertinoColors.label,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Waveform
          if (widget.showWaveform)
            SizedBox(
              height: 60,
              child: VoiceWaveform(amplitudes: _amplitudes, isRecording: true),
            ),

          const SizedBox(height: 16),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel button
              if (_isLocked)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _stopRecording(cancelled: true),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                ),

              if (_isLocked) const SizedBox(width: 24),

              // Stop button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _stopRecording(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.stop_fill,
                    color: CupertinoColors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hints
          if (showCancelHint && !_isLocked)
            Text(
              'Slide left to cancel',
              style: AppTextStyles.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            )
          else if (!_isLocked)
            Text(
              'Slide up to lock',
              style: AppTextStyles.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            )
          else
            Text(
              'Recording locked',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
