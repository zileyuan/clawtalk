/// Enum representing the status of a session.
enum SessionStatus { active, paused, ended, error }

/// A session entity representing a communication session with an agent.
class Session {
  final String id;
  final String key;
  final String agentId;
  final String connectionId;
  final String model;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;

  const Session({
    required this.id,
    this.key = '',
    required this.agentId,
    required this.connectionId,
    this.model = '',
    this.status = SessionStatus.active,
    required this.createdAt,
    this.endedAt,
  });

  Session copyWith({
    String? id,
    String? key,
    String? agentId,
    String? connectionId,
    String? model,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? endedAt,
  }) {
    return Session(
      id: id ?? this.id,
      key: key ?? this.key,
      agentId: agentId ?? this.agentId,
      connectionId: connectionId ?? this.connectionId,
      model: model ?? this.model,
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
        other.key == key &&
        other.agentId == agentId &&
        other.connectionId == connectionId &&
        other.model == model &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.endedAt == endedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      key,
      agentId,
      connectionId,
      model,
      status,
      createdAt,
      endedAt,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, key: $key, agentId: $agentId, model: $model, '
        'status: $status, createdAt: $createdAt, endedAt: $endedAt)';
  }

  /// Create Session from Gateway API response
  factory Session.fromGatewayJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'active';
    final status = switch (statusStr.toLowerCase()) {
      'active' || 'running' => SessionStatus.active,
      'paused' => SessionStatus.paused,
      'ended' || 'completed' => SessionStatus.ended,
      'error' => SessionStatus.error,
      _ => SessionStatus.active,
    };

    // Parse timestamp - Gateway returns milliseconds
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) {
        // Milliseconds timestamp
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        // ISO string format
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Session(
      id:
          json['id'] as String? ??
          json['sessionId'] as String? ??
          json['systemId'] as String? ??
          '',
      key: json['key'] as String? ?? json['sessionKey'] as String? ?? '',
      agentId: json['agentId'] as String? ?? json['agent'] as String? ?? '',
      connectionId: json['connectionId'] as String? ?? '',
      model: json['model'] as String? ?? json['modelName'] as String? ?? '',
      status: status,
      createdAt: parseTimestamp(json['createdAt'] ?? json['updatedAt']),
      endedAt: json['endedAt'] != null ? parseTimestamp(json['endedAt']) : null,
    );
  }
}
