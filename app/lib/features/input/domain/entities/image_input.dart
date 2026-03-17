/// Enum representing the source of an image input.
enum ImageSource { camera, gallery, dragDrop, paste }

/// An image input entity for handling image uploads.
class ImageInput {
  final String id;
  final String path;
  final int sizeBytes;
  final int width;
  final int height;
  final String format;
  final ImageSource source;

  const ImageInput({
    required this.id,
    required this.path,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.format,
    required this.source,
  });

  /// Returns true if the image dimensions are within reasonable bounds.
  bool get hasValidDimensions {
    return width > 0 && height > 0 && width <= 4096 && height <= 4096;
  }

  /// Returns true if the file size is within typical limits (10MB).
  bool get hasValidSize {
    return sizeBytes > 0 && sizeBytes <= 10 * 1024 * 1024;
  }

  /// Returns the aspect ratio of the image.
  double get aspectRatio => width / height;

  /// Returns true if the image is in landscape orientation.
  bool get isLandscape => width > height;

  /// Returns true if the image is in portrait orientation.
  bool get isPortrait => height > width;

  /// Returns true if the image is square.
  bool get isSquare => width == height;

  ImageInput copyWith({
    String? id,
    String? path,
    int? sizeBytes,
    int? width,
    int? height,
    String? format,
    ImageSource? source,
  }) {
    return ImageInput(
      id: id ?? this.id,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      format: format ?? this.format,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageInput &&
        other.id == id &&
        other.path == path &&
        other.sizeBytes == sizeBytes &&
        other.width == width &&
        other.height == height &&
        other.format == format &&
        other.source == source;
  }

  @override
  int get hashCode {
    return Object.hash(id, path, sizeBytes, width, height, format, source);
  }

  @override
  String toString() {
    return 'ImageInput(id: $id, path: $path, sizeBytes: $sizeBytes, '
        'width: $width, height: $height, format: $format, source: $source)';
  }
}
