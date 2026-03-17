import 'package:freezed_annotation/freezed_annotation.dart';

import 'acp_message.dart';
import 'content_block.dart';

part 'acp_event.freezed.dart';
part 'acp_event.g.dart';

/// ACP Event message type
///
/// Events are server-pushed messages that notify the client about state changes,
/// incoming messages, task progress, etc.
@freezed
class AcpEvent extends AcpMessage with _$AcpEvent {
  const AcpEvent._();

  const factory AcpEvent({
    /// Event name/type
    required String event,

    /// Event payload data
    required Map<String, dynamic> payload,

    /// Sequence number for ordered events
    int? seq,

    /// State version for synchronization
    int? stateVersion,
  }) = _AcpEvent;

  @override
  AcpMessageType get messageType => AcpMessageType.event;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'event',
    'event': event,
    'payload': payload,
    if (seq != null) 'seq': seq,
    if (stateVersion != null) 'stateVersion': stateVersion,
  };

  factory AcpEvent.fromJson(Map<String, dynamic> json) => AcpEvent(
    event: json['event'] as String,
    payload: json['payload'] as Map<String, dynamic>,
    seq: json['seq'] as int?,
    stateVersion: json['stateVersion'] as int?,
  );
}

// ============================================================================
// Event type constants
// ============================================================================

/// Standard ACP event types
class AcpEventType {
  AcpEventType._();

  /// Message event - incoming message from agent
  static const String message = 'message';

  /// Tool call event - agent invoking a tool
  static const String toolCall = 'tool_call';

  /// Tool call update - tool status change
  static const String toolCallUpdate = 'tool_call_update';

  /// Done event - session completed
  static const String done = 'done';

  /// Session info update - session state change
  static const String sessionInfoUpdate = 'session_info_update';

  /// Usage update - token usage change
  static const String usageUpdate = 'usage_update';

  /// Error event - server error
  static const String error = 'error';

  /// Status event - connection/server status
  static const String status = 'status';
}

// ============================================================================
// Event payload models
// ============================================================================

/// Message event payload - for incoming agent messages
@freezed
class MessageEventPayload with _$MessageEventPayload {
  const factory MessageEventPayload({
    required String sessionId,
    required String messageId,
    required String role,
    required List<ContentBlock> content,
    DateTime? timestamp,
  }) = _MessageEventPayload;

  factory MessageEventPayload.fromJson(Map<String, dynamic> json) =>
      _$MessageEventPayloadFromJson(json);
}

/// Tool call status
enum ToolCallStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('running')
  running,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed;

  static ToolCallStatus fromString(String value) {
    return ToolCallStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ToolCallStatus.pending,
    );
  }
}

/// Tool call event payload
@freezed
class ToolCallEventPayload with _$ToolCallEventPayload {
  const factory ToolCallEventPayload({
    required String id,
    required String name,
    required ToolCallStatus status,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    String? error,
  }) = _ToolCallEventPayload;

  factory ToolCallEventPayload.fromJson(Map<String, dynamic> json) =>
      _$ToolCallEventPayloadFromJson(json);
}

/// Done event payload
@freezed
class DoneEventPayload with _$DoneEventPayload {
  const factory DoneEventPayload({
    required String sessionId,
    String? reason,
    UsageInfo? usage,
  }) = _DoneEventPayload;

  factory DoneEventPayload.fromJson(Map<String, dynamic> json) =>
      _$DoneEventPayloadFromJson(json);
}

/// Usage information for tokens
@freezed
class UsageInfo with _$UsageInfo {
  const factory UsageInfo({
    required int inputTokens,
    required int outputTokens,
    int? totalTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
  }) = _UsageInfo;

  factory UsageInfo.fromJson(Map<String, dynamic> json) =>
      _$UsageInfoFromJson(json);
}

/// Session info update event payload
@freezed
class SessionInfoUpdatePayload with _$SessionInfoUpdatePayload {
  const factory SessionInfoUpdatePayload({
    required String sessionId,
    String? status,
    Map<String, dynamic>? changes,
  }) = _SessionInfoUpdatePayload;

  factory SessionInfoUpdatePayload.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoUpdatePayloadFromJson(json);
}

/// Usage update event payload
@freezed
class UsageUpdatePayload with _$UsageUpdatePayload {
  const factory UsageUpdatePayload({
    required String sessionId,
    required UsageInfo usage,
  }) = _UsageUpdatePayload;

  factory UsageUpdatePayload.fromJson(Map<String, dynamic> json) =>
      _$UsageUpdatePayloadFromJson(json);
}

/// Error event payload
@freezed
class ErrorEventPayload with _$ErrorEventPayload {
  const factory ErrorEventPayload({
    String? sessionId,
    String? messageId,
    required String code,
    required String message,
    Map<String, dynamic>? details,
  }) = _ErrorEventPayload;

  factory ErrorEventPayload.fromJson(Map<String, dynamic> json) =>
      _$ErrorEventPayloadFromJson(json);
}

/// Status event payload
@freezed
class StatusEventPayload with _$StatusEventPayload {
  const factory StatusEventPayload({
    required String status,
    String? message,
    Map<String, dynamic>? data,
  }) = _StatusEventPayload;

  factory StatusEventPayload.fromJson(Map<String, dynamic> json) =>
      _$StatusEventPayloadFromJson(json);
}

// ============================================================================
// Event parsing extensions
// ============================================================================

/// Extension to parse typed payloads from events
extension AcpEventExtensions on AcpEvent {
  /// Parse message event payload
  MessageEventPayload? get messagePayload => event == AcpEventType.message
      ? MessageEventPayload.fromJson(payload)
      : null;

  /// Parse tool call event payload
  ToolCallEventPayload? get toolCallPayload =>
      event == AcpEventType.toolCall || event == AcpEventType.toolCallUpdate
      ? ToolCallEventPayload.fromJson(payload)
      : null;

  /// Parse done event payload
  DoneEventPayload? get donePayload =>
      event == AcpEventType.done ? DoneEventPayload.fromJson(payload) : null;

  /// Parse session info update payload
  SessionInfoUpdatePayload? get sessionInfoUpdatePayload =>
      event == AcpEventType.sessionInfoUpdate
      ? SessionInfoUpdatePayload.fromJson(payload)
      : null;

  /// Parse usage update payload
  UsageUpdatePayload? get usageUpdatePayload =>
      event == AcpEventType.usageUpdate
      ? UsageUpdatePayload.fromJson(payload)
      : null;

  /// Parse error event payload
  ErrorEventPayload? get errorEventPayload =>
      event == AcpEventType.error ? ErrorEventPayload.fromJson(payload) : null;

  /// Parse status event payload
  StatusEventPayload? get statusPayload => event == AcpEventType.status
      ? StatusEventPayload.fromJson(payload)
      : null;
}
