import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/logger.dart' as log;
import 'voice_waveform.dart';

/// Voice player widget for playing recorded audio
class VoicePlayerWidget extends StatefulWidget {
  /// Path to the audio file
  final String audioPath;

  /// Duration of the audio
  final Duration? duration;

  /// Callback when playback completes
  final VoidCallback? onPlaybackComplete;

  /// Callback when playback is cancelled
  final VoidCallback? onPlaybackCancelled;

  /// Whether to show waveform visualization
  final bool showWaveform;

  /// Waveform data if available
  final List<double>? waveformData;

  /// Whether to auto-play on mount
  final bool autoPlay;

  /// Compact mode for inline display
  final bool compact;

  const VoicePlayerWidget({
    super.key,
    required this.audioPath,
    this.duration,
    this.onPlaybackComplete,
    this.onPlaybackCancelled,
    this.showWaveform = true,
    this.waveformData,
    this.autoPlay = false,
    this.compact = false,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();

    if (widget.autoPlay) {
      _play();
    }
  }

  Future<void> _initAudioPlayer() async {
    // Listen to position updates
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen to duration updates
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      setState(() {
        _playerState = state;
      });
    });

    // Listen to playback completion
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _currentPosition = Duration.zero;
        _playerState = PlayerState.stopped;
      });
      widget.onPlaybackComplete?.call();
    });

    // Set initial duration if provided
    if (widget.duration != null) {
      _totalDuration = widget.duration!;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        _showError('Audio file not found');
        return;
      }

      if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.audioPath));
      }
    } catch (e) {
      log.logger.e('Error playing audio: $e');
      _showError('Failed to play audio');
    }
  }

  Future<void> _pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      log.logger.e('Error pausing audio: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _currentPosition = Duration.zero;
      });
      widget.onPlaybackCancelled?.call();
    } catch (e) {
      log.logger.e('Error stopping audio: $e');
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      log.logger.e('Error seeking audio: $e');
    }
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setPlaybackRate(speed);
      setState(() {
        _playbackSpeed = speed;
      });
    } catch (e) {
      log.logger.e('Error setting playback speed: $e');
    }
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
    return '$minutes:$seconds';
  }

  double get _progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactPlayer();
    }

    return _buildFullPlayer();
  }

  Widget _buildCompactPlayer() {
    final isPlaying = _playerState == PlayerState.playing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CupertinoColors.separator, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: isPlaying ? _pause : _play,
            child: Icon(
              isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 8),

          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: CupertinoColors.systemGrey5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Duration
          Text(
            _formatDuration(_totalDuration - _currentPosition),
            style: AppTextStyles.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPlayer() {
    final isPlaying = _playerState == PlayerState.playing;
    final isPaused = _playerState == PlayerState.paused;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform
          if (widget.showWaveform)
            SizedBox(
              height: 60,
              child: VoiceWaveform(
                amplitudes: widget.waveformData ?? [],
                isPlaying: isPlaying,
                progress: _progress,
                barColor: CupertinoColors.systemGrey4,
                playedColor: AppColors.primary,
                animateBars: isPlaying,
              ),
            ),

          if (widget.showWaveform) const SizedBox(height: 16),

          // Progress slider
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: AppTextStyles.caption.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              Expanded(
                child: CupertinoSlider(
                  value: _progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final position = Duration(
                      milliseconds: (_totalDuration.inMilliseconds * value)
                          .round(),
                    );
                    _seekTo(position);
                  },
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: AppTextStyles.caption.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onPressed: () {
                  final speeds = [0.5, 1.0, 1.5, 2.0];
                  final currentIndex = speeds.indexOf(_playbackSpeed);
                  final nextIndex = (currentIndex + 1) % speeds.length;
                  _setPlaybackSpeed(speeds[nextIndex]);
                },
                child: Text(
                  '${_playbackSpeed}x',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Rewind button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  final newPosition =
                      _currentPosition - const Duration(seconds: 10);
                  _seekTo(
                    newPosition > Duration.zero ? newPosition : Duration.zero,
                  );
                },
                child: const Icon(
                  CupertinoIcons.gobackward_10,
                  color: CupertinoColors.systemGrey,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              // Play/Pause button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: isPlaying ? _pause : _play,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Forward button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  final newPosition =
                      _currentPosition + const Duration(seconds: 10);
                  _seekTo(
                    newPosition < _totalDuration ? newPosition : _totalDuration,
                  );
                },
                child: const Icon(
                  CupertinoIcons.goforward_10,
                  color: CupertinoColors.systemGrey,
                  size: 28,
                ),
              ),

              // Stop button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onPressed: _stop,
                child: const Icon(
                  CupertinoIcons.stop_fill,
                  color: CupertinoColors.systemGrey,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
