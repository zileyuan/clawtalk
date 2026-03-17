import 'dart:io';
import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/image_input.dart';

/// Single image preview item with thumbnail, remove button, and size indicator
class ImagePreviewItem extends StatelessWidget {
  /// The image to display
  final ImageInput image;

  /// Callback when remove button is tapped
  final VoidCallback? onRemove;

  /// Callback when the item is tapped
  final VoidCallback? onTap;

  /// Border radius for the item
  final double borderRadius;

  /// Whether to show size indicator
  final bool showSizeIndicator;

  /// Optional badge text (e.g., "+3" for remaining count)
  final String? badge;

  const ImagePreviewItem({
    super.key,
    required this.image,
    this.onRemove,
    this.onTap,
    this.borderRadius = 12,
    this.showSizeIndicator = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _ImageThumbnail(image: image),
          ),

          // Size indicator
          if (showSizeIndicator)
            Positioned(
              bottom: 4,
              left: 4,
              child: _SizeIndicator(sizeBytes: image.sizeBytes),
            ),

          // Remove button
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: _RemoveButton(onTap: onRemove!),
            ),

          // Badge overlay
          if (badge != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  color: CupertinoColors.black.withAlpha(128),
                  child: Center(
                    child: Text(
                      badge!,
                      style: AppTextStyles.headline2.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Selection overlay on tap
          if (onTap != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(0),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Image thumbnail widget with loading and error handling
class _ImageThumbnail extends StatefulWidget {
  final ImageInput image;

  const _ImageThumbnail({required this.image});

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: CupertinoColors.systemGrey6,
        child: const Center(
          child: Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemGrey,
            size: 24,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(widget.image.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            });
            return const SizedBox.shrink();
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isLoading) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
              return child;
            }
            return const SizedBox.shrink();
          },
        ),
        if (_isLoading)
          Container(
            color: CupertinoColors.systemGrey6,
            child: const Center(child: CupertinoActivityIndicator()),
          ),
      ],
    );
  }
}

/// Size indicator badge
class _SizeIndicator extends StatelessWidget {
  final int sizeBytes;

  const _SizeIndicator({required this.sizeBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withAlpha(179),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        Formatters.formatFileSize(sizeBytes),
        style: AppTextStyles.caption.copyWith(
          color: CupertinoColors.white,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Remove button widget
class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withAlpha(230),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.xmark,
          size: 14,
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}

/// Image info overlay widget for detailed view
class ImageInfoOverlay extends StatelessWidget {
  final ImageInput image;

  const ImageInfoOverlay({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            CupertinoColors.black.withAlpha(204),
            CupertinoColors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${image.width} × ${image.height}',
            style: AppTextStyles.caption.copyWith(color: CupertinoColors.white),
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.formatFileSize(image.sizeBytes),
            style: AppTextStyles.caption.copyWith(
              color: CupertinoColors.white.withAlpha(204),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            image.format.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: CupertinoColors.white.withAlpha(153),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
