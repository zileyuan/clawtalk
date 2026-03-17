import 'content_block.dart';

/// Enum representing the role of a message sender.
enum MessageRole { user, assistant, system }

/// Enum representing the delivery status of a message.
enum MessageStatus { pending, sent, delivered, error }

/// A message entity representing a single message in a conversation.
class Message {
  final String id;
  final String sessionId;
  final MessageRole role;
  final List<ContentBlock> content;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Message({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.status = MessageStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  Message copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    List<ContentBlock>? content,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.role == role &&
        _listEquals(other.content, content) &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sessionId,
      role,
      Object.hashAll(content),
      status,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, sessionId: $sessionId, role: $role, '
        'contentBlocks: ${content.length}, status: $status, createdAt: $createdAt)';
  }

  static bool _listEquals(List<ContentBlock> a, List<ContentBlock> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
