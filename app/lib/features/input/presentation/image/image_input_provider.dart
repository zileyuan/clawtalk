import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/image_input.dart';
import '../../../../core/constants/content_limits.dart';
import '../../../../core/utils/logger.dart';

/// State class for image input
class ImageInputState {
  /// List of selected images
  final List<ImageInput> images;

  /// Whether an operation is in progress
  final bool isLoading;

  /// Current error message if any
  final String? errorMessage;

  /// Validation errors for individual images
  final Map<String, String> validationErrors;

  const ImageInputState({
    required this.images,
    this.isLoading = false,
    this.errorMessage,
    this.validationErrors = const {},
  });

  /// Factory constructor for empty state
  factory ImageInputState.empty() {
    return const ImageInputState(images: []);
  }

  /// Returns true if there are selected images
  bool get hasImages => images.isNotEmpty;

  /// Returns the count of selected images
  int get imageCount => images.length;

  /// Returns true if at max image count
  bool get isAtMaxCount => images.length >= ContentLimits.maxImageCount;

  /// Returns remaining image slots
  int get remainingSlots => ContentLimits.maxImageCount - images.length;

  /// Returns total size of all images
  int get totalSizeBytes => images.fold(0, (sum, img) => sum + img.sizeBytes);

  /// Returns true if total size exceeds limit
  bool get exceedsSizeLimit =>
      totalSizeBytes >
      ContentLimits.maxImageSizeBytes * ContentLimits.maxImageCount;

  /// Returns validation error for a specific image
  String? getErrorForImage(String imageId) => validationErrors[imageId];

  /// Returns true if any validation errors exist
  bool get hasValidationErrors => validationErrors.isNotEmpty;

  ImageInputState copyWith({
    List<ImageInput>? images,
    bool? isLoading,
    String? errorMessage,
    Map<String, String>? validationErrors,
  }) {
    return ImageInputState(
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

/// Notifier for image input state management
class ImageInputNotifier extends StateNotifier<ImageInputState> {
  final ImagePicker _picker = ImagePicker();

  ImageInputNotifier() : super(ImageInputState.empty());

  /// Add images from camera
  Future<void> pickFromCamera() async {
    if (state.isAtMaxCount) {
      _setError('Maximum ${ContentLimits.maxImageCount} images allowed');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: ContentLimits.maxImageWidth.toDouble(),
        maxHeight: ContentLimits.maxImageHeight.toDouble(),
        imageQuality: 90,
      );

      if (photo != null) {
        final image = await _createImageInput(photo, ImageSource.camera);
        if (image != null) {
          _addImage(image);
        }
      }
    } catch (e) {
      Logger.error('Error picking from camera: $e');
      _setError('Failed to capture photo');
    } finally {
      _setLoading(false);
    }
  }

  /// Add images from gallery
  Future<void> pickFromGallery() async {
    if (state.isAtMaxCount) {
      _setError('Maximum ${ContentLimits.maxImageCount} images allowed');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final List<XFile> photos = await _picker.pickMultiImage(
        maxWidth: ContentLimits.maxImageWidth.toDouble(),
        maxHeight: ContentLimits.maxImageHeight.toDouble(),
        imageQuality: 90,
      );

      if (photos.isNotEmpty) {
        final remaining = ContentLimits.maxImageCount - state.images.length;
        final imagesToProcess = photos.take(remaining).toList();

        for (final photo in imagesToProcess) {
          final image = await _createImageInput(photo, ImageSource.gallery);
          if (image != null) {
            _addImage(image);
          }
        }

        if (photos.length > remaining) {
          _setError(
            'Only $remaining images added. Maximum ${ContentLimits.maxImageCount} allowed.',
          );
        }
      }
    } catch (e) {
      Logger.error('Error picking from gallery: $e');
      _setError('Failed to select images');
    } finally {
      _setLoading(false);
    }
  }

  /// Add images from file paths (drag & drop)
  Future<void> addFromPaths(List<String> paths) async {
    if (state.isAtMaxCount) {
      _setError('Maximum ${ContentLimits.maxImageCount} images allowed');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final remaining = ContentLimits.maxImageCount - state.images.length;
      final pathsToProcess = paths.take(remaining).toList();

      for (final path in pathsToProcess) {
        final file = XFile(path);
        final image = await _createImageInput(file, ImageSource.dragDrop);
        if (image != null) {
          _addImage(image);
        }
      }

      if (paths.length > remaining) {
        _setError(
          'Only $remaining images added. Maximum ${ContentLimits.maxImageCount} allowed.',
        );
      }
    } catch (e) {
      Logger.error('Error adding from paths: $e');
      _setError('Failed to add images');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove an image by ID
  void removeImage(String imageId) {
    final updatedImages = state.images
        .where((img) => img.id != imageId)
        .toList();
    final updatedErrors = Map<String, String>.from(state.validationErrors);
    updatedErrors.remove(imageId);

    state = state.copyWith(
      images: updatedImages,
      validationErrors: updatedErrors,
    );
  }

  /// Clear all images
  void clearAll() {
    state = ImageInputState.empty();
  }

  /// Validate all images
  bool validateAll() {
    final errors = <String, String>{};

    for (final image in state.images) {
      final error = _validateImage(image);
      if (error != null) {
        errors[image.id] = error;
      }
    }

    state = state.copyWith(validationErrors: errors);
    return errors.isEmpty;
  }

  /// Replace an existing image
  void replaceImage(String oldImageId, ImageInput newImage) {
    final updatedImages = state.images.map((img) {
      return img.id == oldImageId ? newImage : img;
    }).toList();

    state = state.copyWith(images: updatedImages);
  }

  /// Reorder images
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.images.length ||
        newIndex < 0 ||
        newIndex >= state.images.length) {
      return;
    }

    final updatedImages = List<ImageInput>.from(state.images);
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, item);

    state = state.copyWith(images: updatedImages);
  }

  Future<ImageInput?> _createImageInput(XFile file, ImageSource source) async {
    try {
      final filePath = file.path;
      final fileStat = await File(filePath).stat();
      final extension = path
          .extension(filePath)
          .toLowerCase()
          .replaceAll('.', '');

      // Validate format
      if (!ContentLimits.isValidImageFormat(extension)) {
        _setError('Invalid image format: $extension');
        return null;
      }

      // Validate size
      if (fileStat.size > ContentLimits.maxImageSizeBytes) {
        _setError(
          'Image exceeds maximum size of ${ContentLimits.maxImageSizeBytes ~/ (1024 * 1024)}MB',
        );
        return null;
      }

      // Get image dimensions
      // Note: In production, you'd use the image package or similar
      // For now, we'll use placeholder dimensions
      return ImageInput(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: filePath,
        sizeBytes: fileStat.size,
        width: 0, // Would be populated from actual image metadata
        height: 0, // Would be populated from actual image metadata
        format: extension,
        source: source,
      );
    } catch (e) {
      Logger.error('Error creating image input: $e');
      return null;
    }
  }

  String? _validateImage(ImageInput image) {
    if (!image.hasValidSize) {
      return 'Image size exceeds limit';
    }
    if (!image.hasValidDimensions) {
      return 'Invalid image dimensions';
    }
    if (!ContentLimits.isValidImageFormat(image.format)) {
      return 'Unsupported image format';
    }
    return null;
  }

  void _addImage(ImageInput image) {
    state = state.copyWith(images: [...state.images, image]);
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void _clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Get all selected images
  List<ImageInput> get images => state.images;

  /// Check if valid
  bool get isValid => !state.hasValidationErrors && state.images.isNotEmpty;
}

/// Provider for image input state
final imageInputProvider =
    StateNotifierProvider<ImageInputNotifier, ImageInputState>(
      (ref) => ImageInputNotifier(),
    );

/// Provider for image count
final imageCountProvider = Provider<int>((ref) {
  return ref.watch(imageInputProvider).imageCount;
});

/// Provider for selected images
final selectedImagesProvider = Provider<List<ImageInput>>((ref) {
  return ref.watch(imageInputProvider).images;
});

/// Provider for validation status
final imageValidationProvider = Provider<bool>((ref) {
  return ref.watch(imageInputProvider).isValid;
});

/// Provider for total image size
final totalImageSizeProvider = Provider<int>((ref) {
  return ref.watch(imageInputProvider).totalSizeBytes;
});
