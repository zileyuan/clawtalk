import 'acp_message.dart';
import 'agent_info.dart';
import 'session_info.dart';
import 'task_info.dart';

/// ACP Response message type
///
/// Response messages are sent from server to client in response to requests.
/// The [id] matches the request ID for correlation.
/// [ok] indicates success or failure.
/// [payload] contains response data on success.
/// [error] contains error details on failure.
class AcpResponse extends AcpMessage {
  /// Matching request ID
  final String id;

  /// Success indicator
  final bool ok;

  /// Response payload (when ok=true)
  final Map<String, dynamic>? payload;

  /// Error details (when ok=false)
  final AcpError? error;

  const AcpResponse({
    required this.id,
    required this.ok,
    this.payload,
    this.error,
  });

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

  AcpResponse copyWith({
    String? id,
    bool? ok,
    Map<String, dynamic>? payload,
    AcpError? error,
  }) {
    return AcpResponse(
      id: id ?? this.id,
      ok: ok ?? this.ok,
      payload: payload ?? this.payload,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcpResponse &&
          id == other.id &&
          ok == other.ok &&
          _mapEquals(payload, other.payload) &&
          error == other.error;

  @override
  int get hashCode => Object.hash(id, ok, payload, error);

  @override
  String toString() =>
      'AcpResponse(id: $id, ok: $ok, payload: $payload, error: $error)';
}

bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

/// ACP Error details
class AcpError {
  /// Error code
  final int code;

  /// Error message
  final String message;

  /// Additional error data
  final Map<String, dynamic>? data;

  const AcpError({required this.code, required this.message, this.data});

  AcpError copyWith({int? code, String? message, Map<String, dynamic>? data}) {
    return AcpError(
      code: code ?? this.code,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  factory AcpError.fromJson(Map<String, dynamic> json) => AcpError(
    code: json['code'] as int,
    message: json['message'] as String,
    data: json['data'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcpError &&
          code == other.code &&
          message == other.message &&
          _mapEquals(data, other.data);

  @override
  int get hashCode => Object.hash(code, message, data);

  @override
  String toString() => 'AcpError(code: $code, message: $message, data: $data)';
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
class InitializePayload {
  final int protocol;
  final ServerInfo serverInfo;
  final Map<String, dynamic>? capabilities;

  const InitializePayload({
    required this.protocol,
    required this.serverInfo,
    this.capabilities,
  });

  InitializePayload copyWith({
    int? protocol,
    ServerInfo? serverInfo,
    Map<String, dynamic>? capabilities,
  }) {
    return InitializePayload(
      protocol: protocol ?? this.protocol,
      serverInfo: serverInfo ?? this.serverInfo,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  factory InitializePayload.fromJson(Map<String, dynamic> json) =>
      InitializePayload(
        protocol: json['protocol'] as int,
        serverInfo: ServerInfo.fromJson(
          json['serverInfo'] as Map<String, dynamic>,
        ),
        capabilities: json['capabilities'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
    'protocol': protocol,
    'serverInfo': serverInfo.toJson(),
    if (capabilities != null) 'capabilities': capabilities,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitializePayload &&
          protocol == other.protocol &&
          serverInfo == other.serverInfo &&
          _mapEquals(capabilities, other.capabilities);

  @override
  int get hashCode => Object.hash(protocol, serverInfo, capabilities);
}

/// Server information
class ServerInfo {
  final String id;
  final String name;
  final String version;
  final String? description;

  const ServerInfo({
    required this.id,
    required this.name,
    required this.version,
    this.description,
  });

  ServerInfo copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
  }) {
    return ServerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
    );
  }

  factory ServerInfo.fromJson(Map<String, dynamic> json) => ServerInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    version: json['version'] as String,
    description: json['description'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    if (description != null) 'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerInfo &&
          id == other.id &&
          name == other.name &&
          version == other.version &&
          description == other.description;

  @override
  int get hashCode => Object.hash(id, name, version, description);
}

/// Create session response payload
class CreateSessionPayload {
  final SessionInfo session;

  const CreateSessionPayload({required this.session});

  CreateSessionPayload copyWith({SessionInfo? session}) {
    return CreateSessionPayload(session: session ?? this.session);
  }

  factory CreateSessionPayload.fromJson(Map<String, dynamic> json) =>
      CreateSessionPayload(
        session: SessionInfo.fromJson(json['session'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {'session': session.toJson()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateSessionPayload && session == other.session;

  @override
  int get hashCode => session.hashCode;
}

/// Send message response payload
class SendMessagePayload {
  final String messageId;
  final String? taskId;

  const SendMessagePayload({required this.messageId, this.taskId});

  SendMessagePayload copyWith({String? messageId, String? taskId}) {
    return SendMessagePayload(
      messageId: messageId ?? this.messageId,
      taskId: taskId ?? this.taskId,
    );
  }

  factory SendMessagePayload.fromJson(Map<String, dynamic> json) =>
      SendMessagePayload(
        messageId: json['messageId'] as String,
        taskId: json['taskId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    if (taskId != null) 'taskId': taskId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendMessagePayload &&
          messageId == other.messageId &&
          taskId == other.taskId;

  @override
  int get hashCode => Object.hash(messageId, taskId);
}

/// End session response payload
class EndSessionPayload {
  final String sessionId;
  final String status;

  const EndSessionPayload({required this.sessionId, required this.status});

  EndSessionPayload copyWith({String? sessionId, String? status}) {
    return EndSessionPayload(
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
    );
  }

  factory EndSessionPayload.fromJson(Map<String, dynamic> json) =>
      EndSessionPayload(
        sessionId: json['sessionId'] as String,
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {'sessionId': sessionId, 'status': status};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndSessionPayload &&
          sessionId == other.sessionId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(sessionId, status);
}

/// Get agents response payload
class GetAgentsPayload {
  final List<AgentInfo> agents;

  const GetAgentsPayload({required this.agents});

  GetAgentsPayload copyWith({List<AgentInfo>? agents}) {
    return GetAgentsPayload(agents: agents ?? this.agents);
  }

  factory GetAgentsPayload.fromJson(Map<String, dynamic> json) =>
      GetAgentsPayload(
        agents: (json['agents'] as List)
            .map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'agents': agents.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetAgentsPayload && _listEquals(agents, other.agents);

  @override
  int get hashCode => Object.hashAll(agents);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Cancel task response payload
class CancelTaskPayload {
  final String taskId;
  final String status;

  const CancelTaskPayload({required this.taskId, required this.status});

  CancelTaskPayload copyWith({String? taskId, String? status}) {
    return CancelTaskPayload(
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
    );
  }

  factory CancelTaskPayload.fromJson(Map<String, dynamic> json) =>
      CancelTaskPayload(
        taskId: json['taskId'] as String,
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {'taskId': taskId, 'status': status};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelTaskPayload &&
          taskId == other.taskId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(taskId, status);
}

/// List sessions response payload
class ListSessionsPayload {
  final List<SessionInfo> sessions;

  const ListSessionsPayload({required this.sessions});

  ListSessionsPayload copyWith({List<SessionInfo>? sessions}) {
    return ListSessionsPayload(sessions: sessions ?? this.sessions);
  }

  factory ListSessionsPayload.fromJson(Map<String, dynamic> json) =>
      ListSessionsPayload(
        sessions: (json['sessions'] as List)
            .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'sessions': sessions.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListSessionsPayload && _listEquals(sessions, other.sessions);

  @override
  int get hashCode => Object.hashAll(sessions);
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
