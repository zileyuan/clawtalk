/// Enum representing the type of content in a message block.
enum ContentBlockType {
  text,
  image,
  code,
  markdown,
  thinking,
  toolUse,
  toolResult,
}

/// A block of content within a message.
/// Messages can contain multiple content blocks of different types.
class ContentBlock {
  final String id;
  final ContentBlockType type;
  final String content;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  const ContentBlock({
    required this.id,
    required this.type,
    required this.content,
    this.mimeType,
    this.metadata,
  });

  ContentBlock copyWith({
    String? id,
    ContentBlockType? type,
    String? content,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      mimeType: mimeType ?? this.mimeType,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentBlock &&
        other.id == id &&
        other.type == type &&
        other.content == content &&
        other.mimeType == mimeType &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(id, type, content, mimeType, _mapHash(metadata));
  }

  @override
  String toString() {
    return 'ContentBlock(id: $id, type: $type, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static int _mapHash(Map<String, dynamic>? map) {
    if (map == null) return 0;
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }
}
