import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_info.freezed.dart';
part 'session_info.g.dart';

/// Session status enum
enum SessionStatus {
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('error')
  error;

  static SessionStatus fromString(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionStatus.active,
    );
  }
}

/// Session information model
///
/// Represents a session with an agent, including its state and metadata.
@freezed
class SessionInfo with _$SessionInfo {
  const factory SessionInfo({
    /// Unique session identifier
    required String id,

    /// Agent ID handling this session
    String? agentId,

    /// Session key for routing
    String? sessionKey,

    /// User-defined label
    String? label,

    /// Working directory
    String? cwd,

    /// Current session status
    @Default(SessionStatus.active) SessionStatus status,

    /// Creation timestamp
    required DateTime createdAt,

    /// Last update timestamp
    DateTime? updatedAt,

    /// Additional metadata
    Map<String, dynamic>? meta,

    /// Error message if status is error
    String? error,
  }) = _SessionInfo;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);
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
