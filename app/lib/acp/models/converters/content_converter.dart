import 'dart:convert';

import '../content_block.dart';

/// Content block converter for JSON serialization/deserialization
///
/// Provides utilities for encoding and decoding content blocks
/// to/from JSON format, handling polymorphic serialization.
class ContentConverter {
  ContentConverter._();

  /// Encode a single content block to JSON map
  static Map<String, dynamic> encode(ContentBlock block) {
    return block.toJson();
  }

  /// Encode a list of content blocks to JSON list
  static List<Map<String, dynamic>> encodeList(List<ContentBlock> blocks) {
    return blocks.map((b) => b.toJson()).toList();
  }

  /// Decode a JSON map to content block
  static ContentBlock decode(Map<String, dynamic> json) {
    return ContentBlock.fromJson(json);
  }

  /// Decode a JSON list to content blocks
  static List<ContentBlock> decodeList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => decode(json as Map<String, dynamic>))
        .toList();
  }

  /// Encode a content block to JSON string
  static String encodeToString(ContentBlock block) {
    return jsonEncode(block.toJson());
  }

  /// Decode a JSON string to content block
  static ContentBlock decodeFromString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return decode(json);
  }

  /// Try to decode a content block, returning null on failure
  static ContentBlock? tryDecode(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return decode(json);
    } catch (_) {
      return null;
    }
  }

  /// Create a text content block
  static TextContentBlock text(String text) => TextContentBlock(text: text);

  /// Create an image content block from base64 data
  static ImageContentBlock image({
    required String mimeType,
    required String base64Data,
    int? width,
    int? height,
    int? size,
  }) {
    return ImageContentBlock(
      mimeType: mimeType,
      data: base64Data,
      width: width,
      height: height,
      size: size,
    );
  }

  /// Create an audio content block from base64 data
  static AudioContentBlock audio({
    required String mimeType,
    required String base64Data,
    int? duration,
    int? size,
  }) {
    return AudioContentBlock(
      mimeType: mimeType,
      data: base64Data,
      duration: duration,
      size: size,
    );
  }

  /// Extract text from a list of content blocks
  static String extractText(List<ContentBlock> blocks) {
    return blocks.whereType<TextContentBlock>().map((b) => b.text).join('\n');
  }

  /// Filter image content blocks
  static List<ImageContentBlock> extractImages(List<ContentBlock> blocks) {
    return blocks.whereType<ImageContentBlock>().toList();
  }

  /// Filter audio content blocks
  static List<AudioContentBlock> extractAudio(List<ContentBlock> blocks) {
    return blocks.whereType<AudioContentBlock>().toList();
  }

  /// Check if content blocks contain any images
  static bool hasImages(List<ContentBlock> blocks) {
    return blocks.any((b) => b is ImageContentBlock);
  }

  /// Check if content blocks contain any audio
  static bool hasAudio(List<ContentBlock> blocks) {
    return blocks.any((b) => b is AudioContentBlock);
  }

  /// Check if content blocks are text-only
  static bool isTextOnly(List<ContentBlock> blocks) {
    return blocks.every((b) => b is TextContentBlock);
  }
}
