/// Content block type enum
enum ContentBlockType {
  text,
  image,
  audio;

  String toJson() => name;

  static ContentBlockType fromJson(String value) => ContentBlockType.values
      .firstWhere((e) => e.name == value, orElse: () => ContentBlockType.text);
}

/// Base class for content blocks using sealed class pattern
///
/// Supports polymorphic serialization for different content types:
/// - [TextContentBlock]: Text content
/// - [ImageContentBlock]: Image content with Base64 data
/// - [AudioContentBlock]: Audio content with Base64 data
sealed class ContentBlock {
  const ContentBlock();

  /// Content block type identifier
  ContentBlockType get type;

  /// Convert to JSON map
  Map<String, dynamic> toJson();

  /// Create from JSON map
  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    return switch (typeStr) {
      'text' => TextContentBlock.fromJson(json),
      'image' => ImageContentBlock.fromJson(json),
      'audio' => AudioContentBlock.fromJson(json),
      _ => throw ArgumentError('Unknown content block type: $typeStr'),
    };
  }
}

/// Text content block
class TextContentBlock extends ContentBlock {
  final String text;

  const TextContentBlock({required this.text});

  @override
  ContentBlockType get type => ContentBlockType.text;

  TextContentBlock copyWith({String? text}) =>
      TextContentBlock(text: text ?? this.text);

  factory TextContentBlock.fromJson(Map<String, dynamic> json) =>
      TextContentBlock(text: json['text'] as String);

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextContentBlock && text == other.text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextContentBlock(text: $text)';
}

/// Image content block with Base64 encoded data
class ImageContentBlock extends ContentBlock {
  final String mimeType;
  final String data;
  final int? width;
  final int? height;
  final int? size;

  const ImageContentBlock({
    required this.mimeType,
    required this.data,
    this.width,
    this.height,
    this.size,
  });

  @override
  ContentBlockType get type => ContentBlockType.image;

  ImageContentBlock copyWith({
    String? mimeType,
    String? data,
    int? width,
    int? height,
    int? size,
  }) {
    return ImageContentBlock(
      mimeType: mimeType ?? this.mimeType,
      data: data ?? this.data,
      width: width ?? this.width,
      height: height ?? this.height,
      size: size ?? this.size,
    );
  }

  factory ImageContentBlock.fromJson(Map<String, dynamic> json) =>
      ImageContentBlock(
        mimeType: json['mimeType'] as String,
        data: json['data'] as String,
        width: json['width'] as int?,
        height: json['height'] as int?,
        size: json['size'] as int?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'mimeType': mimeType,
    'data': data,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (size != null) 'size': size,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageContentBlock &&
          mimeType == other.mimeType &&
          data == other.data &&
          width == other.width &&
          height == other.height &&
          size == other.size;

  @override
  int get hashCode => Object.hash(mimeType, data, width, height, size);

  @override
  String toString() =>
      'ImageContentBlock(mimeType: $mimeType, data: ${data.length} chars, '
      'width: $width, height: $height, size: $size)';
}

/// Audio content block with Base64 encoded data
class AudioContentBlock extends ContentBlock {
  final String mimeType;
  final String data;
  final int? duration;
  final int? size;

  const AudioContentBlock({
    required this.mimeType,
    required this.data,
    this.duration,
    this.size,
  });

  @override
  ContentBlockType get type => ContentBlockType.audio;

  AudioContentBlock copyWith({
    String? mimeType,
    String? data,
    int? duration,
    int? size,
  }) {
    return AudioContentBlock(
      mimeType: mimeType ?? this.mimeType,
      data: data ?? this.data,
      duration: duration ?? this.duration,
      size: size ?? this.size,
    );
  }

  factory AudioContentBlock.fromJson(Map<String, dynamic> json) =>
      AudioContentBlock(
        mimeType: json['mimeType'] as String,
        data: json['data'] as String,
        duration: json['duration'] as int?,
        size: json['size'] as int?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'audio',
    'mimeType': mimeType,
    'data': data,
    if (duration != null) 'duration': duration,
    if (size != null) 'size': size,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioContentBlock &&
          mimeType == other.mimeType &&
          data == other.data &&
          duration == other.duration &&
          size == other.size;

  @override
  int get hashCode => Object.hash(mimeType, data, duration, size);

  @override
  String toString() =>
      'AudioContentBlock(mimeType: $mimeType, data: ${data.length} chars, '
      'duration: $duration, size: $size)';
}
