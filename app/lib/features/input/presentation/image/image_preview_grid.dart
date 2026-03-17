import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/image_input.dart';
import 'image_preview_item.dart';

/// Grid view for displaying selected images
class ImagePreviewGrid extends StatelessWidget {
  /// List of selected images
  final List<ImageInput> images;

  /// Callback when an image is removed
  final ValueChanged<ImageInput>? onImageRemoved;

  /// Callback when an image is tapped
  final ValueChanged<ImageInput>? onImageTap;

  /// Maximum number of images to display
  final int maxDisplayCount;

  /// Spacing between grid items
  final double spacing;

  /// Border radius for grid items
  final double borderRadius;

  /// Whether to show add button at the end
  final bool showAddButton;

  /// Callback when add button is tapped
  final VoidCallback? onAddTap;

  const ImagePreviewGrid({
    super.key,
    required this.images,
    this.onImageRemoved,
    this.onImageTap,
    this.maxDisplayCount = 10,
    this.spacing = 8,
    this.borderRadius = 12,
    this.showAddButton = false,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayImages = images.take(maxDisplayCount).toList();
    final remainingCount = images.length - maxDisplayCount;
    final showRemainingBadge = remainingCount > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cross axis count based on available width
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final itemHeight = itemWidth; // Square aspect ratio

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            // Image items
            for (int i = 0; i < displayImages.length; i++)
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: ImagePreviewItem(
                  image: displayImages[i],
                  onRemove: onImageRemoved != null
                      ? () => onImageRemoved!(displayImages[i])
                      : null,
                  onTap: onImageTap != null
                      ? () => onImageTap!(displayImages[i])
                      : null,
                  borderRadius: borderRadius,
                  showSizeIndicator: true,
                  // Show remaining count badge on the last visible item
                  badge: (showRemainingBadge && i == displayImages.length - 1)
                      ? '+$remainingCount'
                      : null,
                ),
              ),
            // Add button
            if (showAddButton && onAddTap != null)
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: _AddImageButton(
                  onTap: onAddTap!,
                  borderRadius: borderRadius,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Calculate optimal cross axis count based on available width
  int _calculateCrossAxisCount(double width) {
    if (width >= 600) {
      return 5; // Large screens: 5 items per row
    } else if (width >= 400) {
      return 4; // Medium screens: 4 items per row
    } else if (width >= 300) {
      return 3; // Small screens: 3 items per row
    }
    return 2; // Very small screens: 2 items per row
  }
}

/// Horizontal scrolling image preview for compact layouts
class ImagePreviewHorizontal extends StatelessWidget {
  /// List of selected images
  final List<ImageInput> images;

  /// Callback when an image is removed
  final ValueChanged<ImageInput>? onImageRemoved;

  /// Callback when an image is tapped
  final ValueChanged<ImageInput>? onImageTap;

  /// Height of the preview items
  final double height;

  /// Width of the preview items
  final double? width;

  /// Spacing between items
  final double spacing;

  /// Border radius for items
  final double borderRadius;

  /// Padding around the list
  final EdgeInsets padding;

  const ImagePreviewHorizontal({
    super.key,
    required this.images,
    this.onImageRemoved,
    this.onImageTap,
    this.height = 100,
    this.width,
    this.spacing = 8,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth = width ?? height;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: images.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final image = images[index];
          return SizedBox(
            width: itemWidth,
            height: height,
            child: ImagePreviewItem(
              image: image,
              onRemove: onImageRemoved != null
                  ? () => onImageRemoved!(image)
                  : null,
              onTap: onImageTap != null ? () => onImageTap!(image) : null,
              borderRadius: borderRadius,
              showSizeIndicator: false,
            ),
          );
        },
      ),
    );
  }
}

/// Add image button widget
class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final double borderRadius;

  const _AddImageButton({required this.onTap, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: CupertinoColors.separator,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.add, size: 32, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                'Add',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
