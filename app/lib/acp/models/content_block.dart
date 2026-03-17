import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_block.freezed.dart';
part 'content_block.g.dart';

/// Content block type enum
enum ContentBlockType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
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
@freezed
class TextContentBlock extends ContentBlock with _$TextContentBlock {
  const TextContentBlock._();

  const factory TextContentBlock({required String text}) = _TextContentBlock;

  @override
  ContentBlockType get type => ContentBlockType.text;

  factory TextContentBlock.fromJson(Map<String, dynamic> json) =>
      _$TextContentBlockFromJson(json);

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

/// Image content block with Base64 encoded data
@freezed
class ImageContentBlock extends ContentBlock with _$ImageContentBlock {
  const ImageContentBlock._();

  const factory ImageContentBlock({
    required String mimeType,
    required String data,
    int? width,
    int? height,
    int? size,
  }) = _ImageContentBlock;

  @override
  ContentBlockType get type => ContentBlockType.image;

  factory ImageContentBlock.fromJson(Map<String, dynamic> json) =>
      _$ImageContentBlockFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'mimeType': mimeType,
    'data': data,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (size != null) 'size': size,
  };
}

/// Audio content block with Base64 encoded data
@freezed
class AudioContentBlock extends ContentBlock with _$AudioContentBlock {
  const AudioContentBlock._();

  const factory AudioContentBlock({
    required String mimeType,
    required String data,
    int? duration,
    int? size,
  }) = _AudioContentBlock;

  @override
  ContentBlockType get type => ContentBlockType.audio;

  factory AudioContentBlock.fromJson(Map<String, dynamic> json) =>
      _$AudioContentBlockFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'audio',
    'mimeType': mimeType,
    'data': data,
    if (duration != null) 'duration': duration,
    if (size != null) 'size': size,
  };
}
