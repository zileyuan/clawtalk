import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';

/// A character/line counter widget for text input
class TextCounter extends StatelessWidget {
  /// Current length of text
  final int currentLength;

  /// Maximum allowed length
  final int maxLength;

  /// Whether to show line count instead of character count
  final bool showLineCount;

  /// Current number of lines (if showLineCount is true)
  final int? currentLines;

  /// Maximum allowed lines (if showLineCount is true)
  final int? maxLines;

  /// Threshold percentage to start showing warning color (0.0 - 1.0)
  final double warningThreshold;

  /// Threshold percentage to start showing danger color (0.0 - 1.0)
  final double dangerThreshold;

  const TextCounter({
    super.key,
    required this.currentLength,
    required this.maxLength,
    this.showLineCount = false,
    this.currentLines,
    this.maxLines,
    this.warningThreshold = 0.8,
    this.dangerThreshold = 0.95,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = currentLength / maxLength;
    final Color counterColor = _getCounterColor(ratio);

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: AppTextStyles.caption.copyWith(color: counterColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            showLineCount
                ? '${currentLines ?? 1}'
                : _formatNumber(currentLength),
            style: AppTextStyles.caption.copyWith(
              color: counterColor,
              fontWeight: ratio >= warningThreshold
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          Text(
            showLineCount
                ? '/${_formatNumber(maxLines ?? maxLength)} lines'
                : '/${_formatNumber(maxLength)}',
            style: AppTextStyles.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  /// Format large numbers with K/M suffix
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Get the appropriate color based on the ratio
  Color _getCounterColor(double ratio) {
    if (ratio >= dangerThreshold) {
      return AppColors.error;
    } else if (ratio >= warningThreshold) {
      return AppColors.warning;
    }
    return CupertinoColors.secondaryLabel;
  }
}

/// Extended counter widget that shows both character and line counts
class ExtendedTextCounter extends StatelessWidget {
  /// Current length of text
  final int currentLength;

  /// Maximum allowed length
  final int maxLength;

  /// Current number of lines
  final int currentLines;

  /// Maximum allowed lines
  final int maxLines;

  /// Threshold percentage to start showing warning color
  final double warningThreshold;

  /// Threshold percentage to start showing danger color
  final double dangerThreshold;

  const ExtendedTextCounter({
    super.key,
    required this.currentLength,
    required this.maxLength,
    required this.currentLines,
    required this.maxLines,
    this.warningThreshold = 0.8,
    this.dangerThreshold = 0.95,
  });

  @override
  Widget build(BuildContext context) {
    final lengthRatio = currentLength / maxLength;
    final linesRatio = currentLines / maxLines;
    final criticalRatio = lengthRatio > linesRatio ? lengthRatio : linesRatio;

    final lengthColor = _getCounterColor(lengthRatio);
    final linesColor = _getCounterColor(linesRatio);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: criticalRatio >= dangerThreshold
            ? AppColors.error.withAlpha(26)
            : criticalRatio >= warningThreshold
            ? AppColors.warning.withAlpha(26)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CounterItem(
            label: 'chars',
            value: currentLength,
            maxValue: maxLength,
            color: lengthColor,
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: CupertinoColors.separator,
          ),
          _CounterItem(
            label: 'lines',
            value: currentLines,
            maxValue: maxLines,
            color: linesColor,
          ),
        ],
      ),
    );
  }

  Color _getCounterColor(double ratio) {
    if (ratio >= dangerThreshold) {
      return AppColors.error;
    } else if (ratio >= warningThreshold) {
      return AppColors.warning;
    }
    return CupertinoColors.secondaryLabel;
  }
}

/// Individual counter item widget
class _CounterItem extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _CounterItem({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '/$maxValue',
              style: AppTextStyles.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: CupertinoColors.tertiaryLabel,
          ),
        ),
      ],
    );
  }
}
