import 'package:freezed_annotation/freezed_annotation.dart';

import 'acp_message.dart';
import 'agent_info.dart';
import 'session_info.dart';
import 'task_info.dart';

part 'acp_response.freezed.dart';
part 'acp_response.g.dart';

/// ACP Response message type
///
/// Response messages are sent from server to client in response to requests.
/// The [id] matches the request ID for correlation.
/// [ok] indicates success or failure.
/// [payload] contains response data on success.
/// [error] contains error details on failure.
@freezed
class AcpResponse extends AcpMessage with _$AcpResponse {
  const AcpResponse._();

  const factory AcpResponse({
    /// Matching request ID
    required String id,

    /// Success indicator
    required bool ok,

    /// Response payload (when ok=true)
    Map<String, dynamic>? payload,

    /// Error details (when ok=false)
    AcpError? error,
  }) = _AcpResponse;

  @override
  AcpMessageType get messageType => AcpMessageType.response;

  /// Check if response indicates success
  bool get isSuccess => ok && error == null;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'res',
    'id': id,
    'ok': ok,
    if (payload != null) 'payload': payload,
    if (error != null) 'error': error!.toJson(),
  };

  factory AcpResponse.fromJson(Map<String, dynamic> json) => AcpResponse(
    id: json['id'] as String,
    ok: json['ok'] as bool,
    payload: json['payload'] as Map<String, dynamic>?,
    error: json['error'] != null
        ? AcpError.fromJson(json['error'] as Map<String, dynamic>)
        : null,
  );
}

/// ACP Error details
@freezed
class AcpError with _$AcpError {
  const AcpError._();

  const factory AcpError({
    /// Error code
    required int code,

    /// Error message
    required String message,

    /// Additional error data
    Map<String, dynamic>? data,
  }) = _AcpError;

  factory AcpError.fromJson(Map<String, dynamic> json) => AcpError(
    code: json['code'] as int,
    message: json['message'] as String,
    data: json['data'] as Map<String, dynamic>?,
  );

  /// Parse error (-32700)
  static const int parseError = -32700;

  /// Invalid request (-32600)
  static const int invalidRequest = -32600;

  /// Method not found (-32601)
  static const int methodNotFound = -32601;

  /// Invalid params (-32602)
  static const int invalidParams = -32602;

  /// Internal error (-32603)
  static const int internalError = -32603;

  /// Auth failed (-32001)
  static const int authFailed = -32001;

  /// Session expired (-32002)
  static const int sessionExpired = -32002;

  /// Rate limited (-32003)
  static const int rateLimited = -32003;

  /// Agent unavailable (-32004)
  static const int agentUnavailable = -32004;

  /// Determine error action based on code
  AcpErrorAction get action => switch (code) {
    authFailed => AcpErrorAction.reauth,
    sessionExpired => AcpErrorAction.reconnect,
    rateLimited => AcpErrorAction.retry,
    _ when code >= -32700 && code <= -32600 => AcpErrorAction.report,
    _ => AcpErrorAction.retry,
  };
}

/// Action to take for an error
enum AcpErrorAction {
  /// Re-authenticate
  reauth,

  /// Reconnect
  reconnect,

  /// Retry request
  retry,

  /// Report to user
  report,

  /// Ignore
  ignore,
}

// ============================================================================
// Response payload models
// ============================================================================

/// Initialize response payload
@freezed
class InitializePayload with _$InitializePayload {
  const factory InitializePayload({
    required int protocol,
    required ServerInfo serverInfo,
    Map<String, dynamic>? capabilities,
  }) = _InitializePayload;

  factory InitializePayload.fromJson(Map<String, dynamic> json) =>
      _$InitializePayloadFromJson(json);
}

/// Server information
@freezed
class ServerInfo with _$ServerInfo {
  const factory ServerInfo({
    required String id,
    required String name,
    required String version,
    String? description,
  }) = _ServerInfo;

  factory ServerInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoFromJson(json);
}

/// Create session response payload
@freezed
class CreateSessionPayload with _$CreateSessionPayload {
  const factory CreateSessionPayload({required SessionInfo session}) =
      _CreateSessionPayload;

  factory CreateSessionPayload.fromJson(Map<String, dynamic> json) =>
      _$CreateSessionPayloadFromJson(json);
}

/// Send message response payload
@freezed
class SendMessagePayload with _$SendMessagePayload {
  const factory SendMessagePayload({
    required String messageId,
    String? taskId,
  }) = _SendMessagePayload;

  factory SendMessagePayload.fromJson(Map<String, dynamic> json) =>
      _$SendMessagePayloadFromJson(json);
}

/// End session response payload
@freezed
class EndSessionPayload with _$EndSessionPayload {
  const factory EndSessionPayload({
    required String sessionId,
    required String status,
  }) = _EndSessionPayload;

  factory EndSessionPayload.fromJson(Map<String, dynamic> json) =>
      _$EndSessionPayloadFromJson(json);
}

/// Get agents response payload
@freezed
class GetAgentsPayload with _$GetAgentsPayload {
  const factory GetAgentsPayload({required List<AgentInfo> agents}) =
      _GetAgentsPayload;

  factory GetAgentsPayload.fromJson(Map<String, dynamic> json) =>
      _$GetAgentsPayloadFromJson(json);
}

/// Cancel task response payload
@freezed
class CancelTaskPayload with _$CancelTaskPayload {
  const factory CancelTaskPayload({
    required String taskId,
    required String status,
  }) = _CancelTaskPayload;

  factory CancelTaskPayload.fromJson(Map<String, dynamic> json) =>
      _$CancelTaskPayloadFromJson(json);
}

/// List sessions response payload
@freezed
class ListSessionsPayload with _$ListSessionsPayload {
  const factory ListSessionsPayload({required List<SessionInfo> sessions}) =
      _ListSessionsPayload;

  factory ListSessionsPayload.fromJson(Map<String, dynamic> json) =>
      _$ListSessionsPayloadFromJson(json);
}

// ============================================================================
// Typed response helpers
// ============================================================================

/// Extension to parse typed payloads from responses
extension AcpResponseExtensions on AcpResponse {
  /// Parse initialize payload
  InitializePayload? get initializePayload => isSuccess && payload != null
      ? InitializePayload.fromJson(payload!)
      : null;

  /// Parse create session payload
  CreateSessionPayload? get createSessionPayload => isSuccess && payload != null
      ? CreateSessionPayload.fromJson(payload!)
      : null;

  /// Parse send message payload
  SendMessagePayload? get sendMessagePayload => isSuccess && payload != null
      ? SendMessagePayload.fromJson(payload!)
      : null;

  /// Parse end session payload
  EndSessionPayload? get endSessionPayload => isSuccess && payload != null
      ? EndSessionPayload.fromJson(payload!)
      : null;

  /// Parse get agents payload
  GetAgentsPayload? get getAgentsPayload =>
      isSuccess && payload != null ? GetAgentsPayload.fromJson(payload!) : null;

  /// Parse cancel task payload
  CancelTaskPayload? get cancelTaskPayload => isSuccess && payload != null
      ? CancelTaskPayload.fromJson(payload!)
      : null;

  /// Parse list sessions payload
  ListSessionsPayload? get listSessionsPayload => isSuccess && payload != null
      ? ListSessionsPayload.fromJson(payload!)
      : null;
}
