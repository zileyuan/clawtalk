/// Session status for tracking conversation states.
enum SessionStatus {
  active,
  archived,
  deleted;

  String toJson() => name;

  static SessionStatus fromJson(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionStatus.active,
    );
  }
}

/// Data model for messaging sessions with JSON serialization.
///
/// A session represents a conversation with a specific connection.
class SessionModel {
  final String id;
  final String connectionId;
  final String title;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SessionModel({
    required this.id,
    required this.connectionId,
    required this.title,
    this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a model from a JSON map.
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      connectionId: json['connectionId'] as String,
      title: json['title'] as String,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      status: SessionStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectionId': connectionId,
      'title': title,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'unreadCount': unreadCount,
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated values.
  SessionModel copyWith({
    String? id,
    String? connectionId,
    String? title,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a new session for a connection.
  factory SessionModel.create({
    required String id,
    required String connectionId,
    String? title,
  }) {
    final now = DateTime.now();
    return SessionModel(
      id: id,
      connectionId: connectionId,
      title: title ?? 'New Conversation',
      lastMessageAt: now,
      unreadCount: 0,
      status: SessionStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update session with a new message.
  SessionModel withNewMessage(String message) {
    return copyWith(
      lastMessage: message,
      lastMessageAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Increment unread count.
  SessionModel incrementUnread() {
    return copyWith(unreadCount: unreadCount + 1, updatedAt: DateTime.now());
  }

  /// Clear unread count.
  SessionModel clearUnread() {
    return copyWith(unreadCount: 0, updatedAt: DateTime.now());
  }

  /// Archive the session.
  SessionModel archive() {
    return copyWith(status: SessionStatus.archived, updatedAt: DateTime.now());
  }

  /// Convert a list of JSON maps to models.
  static List<SessionModel> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => SessionModel.fromJson(json)).toList();
  }

  /// Convert a list of models to JSON maps.
  static List<Map<String, dynamic>> toJsonList(List<SessionModel> models) {
    return models.map((model) => model.toJson()).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SessionModel(id: $id, connectionId: $connectionId, '
        'title: $title, unreadCount: $unreadCount, status: $status)';
  }
}
