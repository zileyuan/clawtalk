import 'package:meta/meta.dart';

/// Session status enum
enum SessionStatus {
  /// Session is active and running
  active,

  /// Session is paused
  paused,

  /// Session has completed successfully
  completed,

  /// Session was cancelled
  cancelled,

  /// Session encountered an error
  error;

  /// Converts the enum value to a JSON string
  String toJson() => name;

  /// Converts a JSON string to the enum value
  static SessionStatus fromJson(String value) => SessionStatus.values
      .firstWhere((e) => e.name == value, orElse: () => SessionStatus.active);

  /// Converts a string to the enum value
  static SessionStatus fromString(String value) => SessionStatus.values
      .firstWhere((e) => e.name == value, orElse: () => SessionStatus.active);
}

/// Session information model
///
/// Represents a session with an agent, including its state and metadata.
@immutable
class SessionInfo {
  /// Unique session identifier
  final String id;

  /// Agent ID handling this session
  final String? agentId;

  /// Session key for routing
  final String? sessionKey;

  /// User-defined label
  final String? label;

  /// Working directory
  final String? cwd;

  /// Current session status
  final SessionStatus status;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  /// Additional metadata
  final Map<String, dynamic>? meta;

  /// Error message if status is error
  final String? error;

  /// Creates a new SessionInfo instance
  SessionInfo({
    required this.id,
    this.agentId,
    this.sessionKey,
    this.label,
    this.cwd,
    this.status = SessionStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.meta,
    this.error,
  });

  /// Creates a copy of this SessionInfo with the given fields replaced
  SessionInfo copyWith({
    String? id,
    String? agentId,
    String? sessionKey,
    String? label,
    String? cwd,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? meta,
    String? error,
  }) => SessionInfo(
    id: id ?? this.id,
    agentId: agentId ?? this.agentId,
    sessionKey: sessionKey ?? this.sessionKey,
    label: label ?? this.label,
    cwd: cwd ?? this.cwd,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    meta: meta ?? this.meta,
    error: error ?? this.error,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionInfo &&
          other.id == id &&
          other.agentId == agentId &&
          other.sessionKey == sessionKey &&
          other.label == label &&
          other.cwd == cwd &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          _mapEquals(other.meta, meta) &&
          other.error == error;

  @override
  int get hashCode => Object.hash(
    id,
    agentId,
    sessionKey,
    label,
    cwd,
    status,
    createdAt,
    updatedAt,
    meta,
    error,
  );

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// Creates a SessionInfo from a JSON map
  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
    id: json['id'] as String,
    agentId: json['agentId'] as String?,
    sessionKey: json['sessionKey'] as String?,
    label: json['label'] as String?,
    cwd: json['cwd'] as String?,
    status: json['status'] != null
        ? SessionStatus.fromJson(json['status'] as String)
        : SessionStatus.active,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    meta: json['meta'] as Map<String, dynamic>?,
    error: json['error'] as String?,
  );

  /// Converts this SessionInfo to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    if (agentId != null) 'agentId': agentId,
    if (sessionKey != null) 'sessionKey': sessionKey,
    if (label != null) 'label': label,
    if (cwd != null) 'cwd': cwd,
    'status': status.toJson(),
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (meta != null) 'meta': meta,
    if (error != null) 'error': error,
  };
}

/// Extension for SessionInfo convenience methods
extension SessionInfoExtensions on SessionInfo {
  /// Check if session is active
  bool get isActive => status == SessionStatus.active;

  /// Check if session is completed
  bool get isCompleted => status == SessionStatus.completed;

  /// Check if session has error
  bool get hasError => status == SessionStatus.error || error != null;

  /// Check if session is paused
  bool get isPaused => status == SessionStatus.paused;

  /// Check if session is cancelled
  bool get isCancelled => status == SessionStatus.cancelled;
}
