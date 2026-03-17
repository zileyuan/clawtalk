import 'dart:math' as math;
import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';

/// Voice waveform visualization widget for audio recording/playback
class VoiceWaveform extends StatelessWidget {
  /// List of amplitude values for the waveform
  final List<double> amplitudes;

  /// Whether currently recording (shows animated bars)
  final bool isRecording;

  /// Whether currently playing (shows progress)
  final bool isPlaying;

  /// Current playback progress (0.0 to 1.0)
  final double progress;

  /// Color for the waveform bars
  final Color barColor;

  /// Color for the played portion during playback
  final Color playedColor;

  /// Height of the waveform
  final double height;

  /// Width of each bar
  final double barWidth;

  /// Spacing between bars
  final double barSpacing;

  /// Minimum bar height
  final double minBarHeight;

  /// Maximum bar height
  final double maxBarHeight;

  /// Whether to animate bars during recording
  final bool animateBars;

  const VoiceWaveform({
    super.key,
    required this.amplitudes,
    this.isRecording = false,
    this.isPlaying = false,
    this.progress = 0.0,
    this.barColor = CupertinoColors.systemGrey,
    this.playedColor = CupertinoColors.activeBlue,
    this.height = 60,
    this.barWidth = 3,
    this.barSpacing = 2,
    this.minBarHeight = 4,
    this.maxBarHeight = 60,
    this.animateBars = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final barCount = (width / (barWidth + barSpacing)).floor();

        // Use provided amplitudes or generate placeholder
        final displayAmplitudes = amplitudes.isNotEmpty
            ? amplitudes
            : List.generate(barCount, (index) => 0.0);

        // Calculate which bars are played
        final playedBarCount = (barCount * progress).floor();

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: height,
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                math.min(barCount, displayAmplitudes.length),
                (index) {
                  final amplitude = displayAmplitudes[index];
                  final isPlayed = isPlaying && index < playedBarCount;

                  return _WaveformBar(
                    amplitude: amplitude,
                    width: barWidth,
                    minHeight: minBarHeight,
                    maxHeight: maxBarHeight,
                    color: isPlayed ? playedColor : barColor,
                    isActive:
                        isRecording && index > displayAmplitudes.length - 10,
                    animate: animateBars && isRecording,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Individual waveform bar
class _WaveformBar extends StatefulWidget {
  final double amplitude;
  final double width;
  final double minHeight;
  final double maxHeight;
  final Color color;
  final bool isActive;
  final bool animate;

  const _WaveformBar({
    required this.amplitude,
    required this.width,
    required this.minHeight,
    required this.maxHeight,
    required this.color,
    this.isActive = false,
    this.animate = false,
  });

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_WaveformBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert amplitude (typically -160 to 0 dB) to height
    final normalizedAmplitude = _normalizeAmplitude(widget.amplitude);
    final targetHeight =
        widget.minHeight +
        (normalizedAmplitude * (widget.maxHeight - widget.minHeight));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final height = widget.animate && widget.isActive
            ? targetHeight * (0.7 + 0.3 * _animation.value)
            : targetHeight;

        return Container(
          width: widget.width,
          height: height,
          margin: EdgeInsets.symmetric(horizontal: widget.width / 2),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.primary : widget.color,
            borderRadius: BorderRadius.circular(widget.width / 2),
          ),
        );
      },
    );
  }

  /// Normalize amplitude from dB range to 0.0 - 1.0
  double _normalizeAmplitude(double amplitude) {
    // Typical range: -160 dB (silent) to 0 dB (max)
    const minDb = -160.0;
    const maxDb = 0.0;

    // Clamp and normalize
    final clamped = amplitude.clamp(minDb, maxDb);
    return ((clamped - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
  }
}

/// Animated voice waveform that generates random bars for visual effect
class AnimatedVoiceWaveform extends StatefulWidget {
  final double height;
  final double barWidth;
  final double barSpacing;
  final int barCount;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedVoiceWaveform({
    super.key,
    this.height = 60,
    this.barWidth = 3,
    this.barSpacing = 2,
    this.barCount = 40,
    this.activeColor = CupertinoColors.activeBlue,
    this.inactiveColor = CupertinoColors.systemGrey4,
  });

  @override
  State<AnimatedVoiceWaveform> createState() => _AnimatedVoiceWaveformState();
}

class _AnimatedVoiceWaveformState extends State<AnimatedVoiceWaveform>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 20)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimation();
  }

  void _startAnimation() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final height = widget.height * _animations[index].value;

              return Container(
                width: widget.barWidth,
                height: height,
                margin: EdgeInsets.symmetric(horizontal: widget.barSpacing / 2),
                decoration: BoxDecoration(
                  color: widget.activeColor.withAlpha(
                    (128 + 127 * _animations[index].value).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Static waveform for displaying recorded audio
class StaticVoiceWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final double progress;
  final double height;
  final Color barColor;
  final Color progressColor;

  const StaticVoiceWaveform({
    super.key,
    required this.amplitudes,
    this.progress = 0.0,
    this.height = 40,
    this.barColor = CupertinoColors.systemGrey4,
    this.progressColor = CupertinoColors.activeBlue,
  });

  @override
  Widget build(BuildContext context) {
    return VoiceWaveform(
      amplitudes: amplitudes,
      isRecording: false,
      isPlaying: progress > 0,
      progress: progress,
      barColor: barColor,
      playedColor: progressColor,
      height: height,
      animateBars: false,
    );
  }
}
