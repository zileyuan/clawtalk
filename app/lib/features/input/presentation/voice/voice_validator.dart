import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/constants/content_limits.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/voice_input.dart';
import 'voice_input_provider.dart';

/// Widget displaying voice recording validation status
class VoiceValidator extends StatelessWidget {
  /// The voice input to validate
  final VoiceInput? voiceInput;

  /// Whether to show compact view
  final bool compact;

  /// Whether to show waveform preview
  final bool showWaveform;

  /// Waveform data if available
  final List<double>? waveformData;

  const VoiceValidator({
    super.key,
    this.voiceInput,
    this.compact = false,
    this.showWaveform = false,
    this.waveformData,
  });

  @override
  Widget build(BuildContext context) {
    if (voiceInput == null) {
      return compact ? const SizedBox.shrink() : _buildEmptyState();
    }

    final durationValid = voiceInput!.hasValidDuration;
    final sizeValid = voiceInput!.hasValidSize;
    final isValid = durationValid && sizeValid;

    if (compact) {
      return _buildCompactView(
        isValid: isValid,
        durationValid: durationValid,
        sizeValid: sizeValid,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withAlpha(13)
            : AppColors.error.withAlpha(13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isValid ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overall status
          _buildStatusRow(
            icon: isValid
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.exclamationmark_triangle_fill,
            color: isValid ? AppColors.success : AppColors.error,
            label: isValid ? 'Recording valid' : 'Validation issues found',
          ),

          const SizedBox(height: 12),

          // Duration validation
          _buildStatusRow(
            icon: durationValid
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.xmark_circle,
            color: durationValid ? AppColors.success : AppColors.error,
            label:
                'Duration: ${_formatDuration(voiceInput!.duration)} / ${_formatDuration(Duration(seconds: ContentLimits.maxVoiceDurationSeconds))}',
          ),

          const SizedBox(height: 8),

          // Size validation
          _buildStatusRow(
            icon: sizeValid
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.xmark_circle,
            color: sizeValid ? AppColors.success : AppColors.error,
            label:
                'Size: ${Formatters.formatFileSize(voiceInput!.sizeBytes)} / ${Formatters.formatFileSize(ContentLimits.maxVoiceSizeBytes)}',
          ),

          // Format info
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: CupertinoIcons.doc,
            label: 'Format: ${voiceInput!.format.toUpperCase()}',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.separator, width: 1),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.mic, size: 18, color: CupertinoColors.systemGrey),
          const SizedBox(width: 8),
          Text(
            'No recording available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView({
    required bool isValid,
    required bool durationValid,
    required bool sizeValid,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid
              ? CupertinoIcons.checkmark_circle_fill
              : CupertinoIcons.exclamationmark_triangle_fill,
          size: 16,
          color: isValid ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: 6),
        if (voiceInput != null)
          Text(
            _formatDuration(voiceInput!.duration),
            style: AppTextStyles.caption.copyWith(
              color: durationValid
                  ? CupertinoColors.secondaryLabel
                  : AppColors.error,
            ),
          ),
        if (voiceInput != null) const SizedBox(width: 8),
        if (voiceInput != null)
          Text(
            Formatters.formatFileSize(voiceInput!.sizeBytes),
            style: AppTextStyles.caption.copyWith(
              color: sizeValid
                  ? CupertinoColors.secondaryLabel
                  : AppColors.error,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CupertinoColors.secondaryLabel),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Recording duration indicator with validation
class RecordingDurationIndicator extends StatelessWidget {
  final Duration duration;
  final bool showWarning;

  const RecordingDurationIndicator({
    super.key,
    required this.duration,
    this.showWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxDuration = Duration(
      seconds: ContentLimits.maxVoiceDurationSeconds,
    );
    final isNearLimit = duration >= maxDuration - const Duration(seconds: 30);
    final isOverLimit = duration > maxDuration;

    final color = isOverLimit
        ? AppColors.error
        : isNearLimit && showWarning
        ? AppColors.warning
        : CupertinoColors.secondaryLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOverLimit
            ? AppColors.error.withAlpha(26)
            : isNearLimit && showWarning
            ? AppColors.warning.withAlpha(26)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverLimit
              ? AppColors.error
              : isNearLimit && showWarning
              ? AppColors.warning
              : CupertinoColors.separator,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.mic_fill,
            size: 14,
            color: isOverLimit
                ? AppColors.error
                : isNearLimit && showWarning
                ? AppColors.warning
                : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatDuration(duration),
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' / ${_formatDuration(maxDuration)}',
            style: AppTextStyles.caption.copyWith(
              color: CupertinoColors.tertiaryLabel,
            ),
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
}

/// Voice recording status chip
class VoiceRecordingChip extends StatelessWidget {
  final RecordingState state;
  final Duration? duration;
  final VoidCallback? onTap;

  const VoiceRecordingChip({
    super.key,
    required this.state,
    this.duration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _getStateInfo();

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(128), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (duration != null) ...[
              const SizedBox(width: 4),
              Text(
                _formatDuration(duration!),
                style: AppTextStyles.caption.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _getStateInfo() {
    switch (state) {
      case RecordingState.recording:
        return (CupertinoIcons.mic_fill, AppColors.error, 'Recording');
      case RecordingState.paused:
        return (CupertinoIcons.pause_fill, AppColors.warning, 'Paused');
      case RecordingState.stopping:
        return (
          CupertinoIcons.stop_fill,
          CupertinoColors.systemGrey,
          'Stopping',
        );
      case RecordingState.error:
        return (
          CupertinoIcons.exclamationmark_triangle_fill,
          AppColors.error,
          'Error',
        );
      case RecordingState.idle:
      default:
        return (CupertinoIcons.mic, AppColors.success, 'Ready');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '($minutes:$seconds)';
  }
}
