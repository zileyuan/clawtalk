/// Message types supported by the messaging system.
enum MessageType {
  text,
  image,
  audio,
  video,
  file,
  system;

  String toJson() => name;

  static MessageType fromJson(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Message status for tracking delivery and read states.
enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed;

  String toJson() => name;

  static MessageStatus fromJson(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.pending,
    );
  }
}

/// Data model for messages with JSON serialization.
class MessageModel {
  final String id;
  final String sessionId;
  final String connectionId;
  final MessageType type;
  final String content;
  final String? metadata;
  final MessageStatus status;
  final bool isFromUser;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorMessage;

  const MessageModel({
    required this.id,
    required this.sessionId,
    required this.connectionId,
    required this.type,
    required this.content,
    this.metadata,
    required this.status,
    required this.isFromUser,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.errorMessage,
  });

  /// Create a model from a JSON map.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      connectionId: json['connectionId'] as String,
      type: MessageType.fromJson(json['type'] as String),
      content: json['content'] as String,
      metadata: json['metadata'] as String?,
      status: MessageStatus.fromJson(json['status'] as String),
      isFromUser: json['isFromUser'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'connectionId': connectionId,
      'type': type.toJson(),
      'content': content,
      'metadata': metadata,
      'status': status.toJson(),
      'isFromUser': isFromUser,
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  /// Create a copy with updated values.
  MessageModel copyWith({
    String? id,
    String? sessionId,
    String? connectionId,
    MessageType? type,
    String? content,
    String? metadata,
    MessageStatus? status,
    bool? isFromUser,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? errorMessage,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      connectionId: connectionId ?? this.connectionId,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      isFromUser: isFromUser ?? this.isFromUser,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Create a text message.
  factory MessageModel.text({
    required String id,
    required String sessionId,
    required String connectionId,
    required String content,
    required bool isFromUser,
    MessageStatus status = MessageStatus.pending,
  }) {
    return MessageModel(
      id: id,
      sessionId: sessionId,
      connectionId: connectionId,
      type: MessageType.text,
      content: content,
      status: status,
      isFromUser: isFromUser,
      createdAt: DateTime.now(),
    );
  }

  /// Create a system message.
  factory MessageModel.system({
    required String id,
    required String sessionId,
    required String connectionId,
    required String content,
  }) {
    return MessageModel(
      id: id,
      sessionId: sessionId,
      connectionId: connectionId,
      type: MessageType.system,
      content: content,
      status: MessageStatus.delivered,
      isFromUser: false,
      createdAt: DateTime.now(),
    );
  }

  /// Convert a list of JSON maps to models.
  static List<MessageModel> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => MessageModel.fromJson(json)).toList();
  }

  /// Convert a list of models to JSON maps.
  static List<Map<String, dynamic>> toJsonList(List<MessageModel> models) {
    return models.map((model) => model.toJson()).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageModel(id: $id, type: $type, status: $status, '
        'isFromUser: $isFromUser, createdAt: $createdAt)';
  }
}
