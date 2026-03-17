import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/constants/content_limits.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/image_input.dart';

/// Widget displaying image validation status
class ImageValidator extends StatelessWidget {
  /// List of images to validate
  final List<ImageInput> images;

  /// Whether to show individual image validation
  final bool showIndividualValidation;

  /// Whether to show compact view
  final bool compact;

  const ImageValidator({
    super.key,
    required this.images,
    this.showIndividualValidation = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final validationResults = _validateImages();
    final hasErrors = validationResults.values.any((result) => !result.isValid);
    final totalSize = images.fold<int>(0, (sum, img) => sum + img.sizeBytes);
    final countValid = images.length <= ContentLimits.maxImageCount;
    final sizeValid =
        totalSize <=
        ContentLimits.maxImageSizeBytes * ContentLimits.maxImageCount;

    if (compact) {
      return _buildCompactView(
        hasErrors: hasErrors,
        countValid: countValid,
        sizeValid: sizeValid,
        totalSize: totalSize,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasErrors
            ? AppColors.error.withAlpha(13)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasErrors ? AppColors.error : CupertinoColors.separator,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overall status
          _buildStatusRow(
            icon: hasErrors
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.checkmark_circle_fill,
            color: hasErrors ? AppColors.error : AppColors.success,
            label: hasErrors ? 'Validation issues found' : 'All images valid',
          ),

          const SizedBox(height: 12),

          // Count validation
          _buildStatusRow(
            icon: countValid
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.xmark_circle,
            color: countValid ? AppColors.success : AppColors.error,
            label: 'Count: ${images.length}/${ContentLimits.maxImageCount}',
          ),

          const SizedBox(height: 8),

          // Size validation
          _buildStatusRow(
            icon: sizeValid
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.xmark_circle,
            color: sizeValid ? AppColors.success : AppColors.error,
            label: 'Total size: ${Formatters.formatFileSize(totalSize)}',
          ),

          // Individual validation errors
          if (showIndividualValidation && hasErrors)
            ..._buildIndividualErrors(validationResults),
        ],
      ),
    );
  }

  Widget _buildCompactView({
    required bool hasErrors,
    required bool countValid,
    required bool sizeValid,
    required int totalSize,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasErrors
              ? CupertinoIcons.exclamationmark_triangle_fill
              : CupertinoIcons.checkmark_circle_fill,
          size: 16,
          color: hasErrors ? AppColors.error : AppColors.success,
        ),
        const SizedBox(width: 4),
        Text(
          '${images.length}/${ContentLimits.maxImageCount}',
          style: AppTextStyles.caption.copyWith(
            color: countValid
                ? CupertinoColors.secondaryLabel
                : AppColors.error,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          Formatters.formatFileSize(totalSize),
          style: AppTextStyles.caption.copyWith(
            color: sizeValid ? CupertinoColors.secondaryLabel : AppColors.error,
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

  List<Widget> _buildIndividualErrors(
    Map<String, ImageValidationResult> results,
  ) {
    final errors = results.entries
        .where((e) => !e.value.isValid)
        .map((e) => e.value)
        .toList();

    if (errors.isEmpty) return [];

    return [
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 8),
      Text(
        'Image Issues:',
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      ...errors.map(
        (error) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.xmark_circle,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error.errorMessage ?? 'Unknown error',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Map<String, ImageValidationResult> _validateImages() {
    final results = <String, ImageValidationResult>{};

    for (final image in images) {
      String? error;

      if (!image.hasValidSize) {
        error =
            'Exceeds size limit (${Formatters.formatFileSize(ContentLimits.maxImageSizeBytes)})';
      } else if (!image.hasValidDimensions) {
        error = 'Invalid dimensions (${image.width}x${image.height})';
      } else if (!ContentLimits.isValidImageFormat(image.format)) {
        error = 'Unsupported format (.${image.format})';
      }

      results[image.id] = ImageValidationResult(
        imageId: image.id,
        isValid: error == null,
        errorMessage: error,
      );
    }

    return results;
  }
}

/// Validation result for a single image
class ImageValidationResult {
  final String imageId;
  final bool isValid;
  final String? errorMessage;

  const ImageValidationResult({
    required this.imageId,
    required this.isValid,
    this.errorMessage,
  });
}

/// Compact image counter with validation indicator
class ImageCounter extends StatelessWidget {
  final int currentCount;
  final int maxCount;
  final VoidCallback? onTap;

  const ImageCounter({
    super.key,
    required this.currentCount,
    this.maxCount = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = currentCount <= maxCount;
    final isNearLimit = currentCount >= maxCount * 0.8;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: !isValid
              ? AppColors.error.withAlpha(26)
              : isNearLimit
              ? AppColors.warning.withAlpha(26)
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !isValid
                ? AppColors.error
                : isNearLimit
                ? AppColors.warning
                : CupertinoColors.separator,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 16,
              color: !isValid ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '$currentCount',
              style: AppTextStyles.bodyMedium.copyWith(
                color: !isValid
                    ? AppColors.error
                    : isNearLimit
                    ? AppColors.warning
                    : CupertinoColors.label,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '/$maxCount',
              style: AppTextStyles.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
