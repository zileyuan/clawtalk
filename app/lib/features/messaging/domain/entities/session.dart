/// Enum representing the status of a session.
enum SessionStatus { active, paused, ended, error }

/// A session entity representing a communication session with an agent.
class Session {
  final String id;
  final String agentId;
  final String connectionId;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;

  const Session({
    required this.id,
    required this.agentId,
    required this.connectionId,
    this.status = SessionStatus.active,
    required this.createdAt,
    this.endedAt,
  });

  Session copyWith({
    String? id,
    String? agentId,
    String? connectionId,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? endedAt,
  }) {
    return Session(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      connectionId: connectionId ?? this.connectionId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session &&
        other.id == id &&
        other.agentId == agentId &&
        other.connectionId == connectionId &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.endedAt == endedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, agentId, connectionId, status, createdAt, endedAt);
  }

  @override
  String toString() {
    return 'Session(id: $id, agentId: $agentId, connectionId: $connectionId, '
        'status: $status, createdAt: $createdAt, endedAt: $endedAt)';
  }
}
