import 'message.dart';

/// A conversation entity representing a collection of messages.
class Conversation {
  final String id;
  final String connectionId;
  final String? agentId;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    required this.connectionId,
    this.agentId,
    this.messages = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Conversation copyWith({
    String? id,
    String? connectionId,
    String? agentId,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      agentId: agentId ?? this.agentId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation &&
        other.id == id &&
        other.connectionId == connectionId &&
        other.agentId == agentId &&
        _listEquals(other.messages, messages) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      connectionId,
      agentId,
      Object.hashAll(messages),
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, connectionId: $connectionId, agentId: $agentId, '
        'messageCount: ${messages.length}, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  static bool _listEquals(List<Message> a, List<Message> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
