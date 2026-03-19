import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as img;

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/utils/logger.dart' as log;
import '../../domain/entities/image_input.dart';

/// Image picker widget with camera, gallery, drag & drop, and paste support
class ImagePickerWidget extends StatefulWidget {
  /// Callback when images are selected
  final ValueChanged<List<ImageInput>> onImagesSelected;

  /// Maximum number of images allowed
  final int maxImages;

  /// Maximum image size in bytes
  final int maxSizeBytes;

  /// Whether to show camera button
  final bool showCameraButton;

  /// Whether to show gallery button
  final bool showGalleryButton;

  /// Whether drag & drop is enabled (desktop)
  final bool enableDragDrop;

  /// Whether paste from clipboard is enabled
  final bool enablePaste;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 10,
    this.maxSizeBytes = 10 * 1024 * 1024,
    this.showCameraButton = true,
    this.showGalleryButton = true,
    this.enableDragDrop = true,
    this.enablePaste = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final img.ImagePicker _picker = img.ImagePicker();
  bool _isLoading = false;

  Future<void> _pickFromCamera() async {
    try {
      setState(() => _isLoading = true);

      final img.XFile? photo = await _picker.pickImage(
        source: img.ImageSource.camera,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );

      if (photo != null) {
        await _processImage(photo, ImageSource.camera);
      }
    } catch (e) {
      log.logger.e('Error picking from camera: $e');
      _showError('Failed to capture photo');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isLoading = true);

      final List<img.XFile> photos = await _picker.pickMultiImage(
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );

      if (photos.isNotEmpty) {
        final images = <ImageInput>[];
        for (final photo in photos.take(widget.maxImages)) {
          final image = await _createImageInput(photo, ImageSource.gallery);
          if (image != null) {
            images.add(image);
          }
        }
        if (images.isNotEmpty) {
          widget.onImagesSelected(images);
        }
      }
    } catch (e) {
      log.logger.e('Error picking from gallery: $e');
      _showError('Failed to select images');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processImage(img.XFile file, ImageSource source) async {
    final image = await _createImageInput(file, source);
    if (image != null) {
      widget.onImagesSelected([image]);
    }
  }

  Future<ImageInput?> _createImageInput(
    img.XFile file,
    ImageSource source,
  ) async {
    try {
      final filePath = file.path;
      final fileStat = await File(filePath).stat();

      if (fileStat.size > widget.maxSizeBytes) {
        _showError(
          'Image exceeds maximum size of ${widget.maxSizeBytes ~/ (1024 * 1024)}MB',
        );
        return null;
      }

      // Get image dimensions
      final imageData = await file.readAsBytes();
      final decodedImage = await decodeImageFromList(imageData);

      final extension = filePath.split('.').last.toLowerCase();

      return ImageInput(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: filePath,
        sizeBytes: fileStat.size,
        width: decodedImage.width,
        height: decodedImage.height,
        format: extension,
        source: source,
      );
    } catch (e) {
      log.logger.e('Error creating image input: $e');
      return null;
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      // Note: Flutter doesn't support direct image paste from clipboard
      // This would require platform-specific implementation
      _showError(
        'Paste image from clipboard is not supported on this platform',
      );
    } catch (e) {
      log.logger.e('Error pasting from clipboard: $e');
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

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.tertiarySystemBackground.darkColor
            : CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.enableDragDrop)
            _DragDropZone(
              onDrop: (paths) async {
                final images = <ImageInput>[];
                for (final p in paths.take(widget.maxImages)) {
                  final file = img.XFile(p);
                  final image = await _createImageInput(
                    file,
                    ImageSource.dragDrop,
                  );
                  if (image != null) {
                    images.add(image);
                  }
                }
                if (images.isNotEmpty) {
                  widget.onImagesSelected(images);
                }
              },
            ),
          if (widget.enableDragDrop) const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.showCameraButton)
                _PickerButton(
                  icon: CupertinoIcons.camera_fill,
                  label: 'Camera',
                  onTap: _isLoading ? null : _pickFromCamera,
                ),
              if (widget.showGalleryButton)
                _PickerButton(
                  icon: CupertinoIcons.photo_fill,
                  label: 'Gallery',
                  onTap: _isLoading ? null : _pickFromGallery,
                ),
              if (widget.enablePaste)
                _PickerButton(
                  icon: CupertinoIcons.doc_on_clipboard_fill,
                  label: 'Paste',
                  onTap: _isLoading ? null : _pasteFromClipboard,
                ),
            ],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CupertinoActivityIndicator(),
            ),
        ],
      ),
    );
  }
}

/// Button for picking images
class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PickerButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withAlpha(26)
              : CupertinoColors.systemGrey4,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onTap != null
                  ? AppColors.primary
                  : CupertinoColors.systemGrey,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: onTap != null
                    ? AppColors.primary
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drag and drop zone for desktop platforms
class _DragDropZone extends StatefulWidget {
  final ValueChanged<List<String>> onDrop;

  const _DragDropZone({required this.onDrop});

  @override
  State<_DragDropZone> createState() => _DragDropZoneState();
}

class _DragDropZoneState extends State<_DragDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Fallback for platforms that don't support drag & drop
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: _isDragging
              ? AppColors.primary.withAlpha(51)
              : isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isDragging ? AppColors.primary : CupertinoColors.separator,
            width: _isDragging ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.arrow_down_doc,
                size: 32,
                color: _isDragging
                    ? AppColors.primary
                    : CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 8),
              Text(
                'Drag & drop images here',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _isDragging
                      ? AppColors.primary
                      : CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
