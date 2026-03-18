import 'acp_message.dart';
import 'content_block.dart';

/// ACP Request message type
///
/// Request messages are sent from client to server with an ID for correlation.
/// The [method] field specifies the action to perform.
/// The [params] field contains method-specific parameters.
class AcpRequest extends AcpMessage {
  /// Unique request ID for correlation with response
  final String id;

  /// Method name to invoke
  final String method;

  /// Method-specific parameters
  final Map<String, dynamic> params;

  const AcpRequest({
    required this.id,
    required this.method,
    required this.params,
  });

  @override
  AcpMessageType get messageType => AcpMessageType.request;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'req',
    'id': id,
    'method': method,
    'params': params,
  };

  factory AcpRequest.fromJson(Map<String, dynamic> json) => AcpRequest(
    id: json['id'] as String,
    method: json['method'] as String,
    params: json['params'] as Map<String, dynamic>,
  );

  AcpRequest copyWith({
    String? id,
    String? method,
    Map<String, dynamic>? params,
  }) {
    return AcpRequest(
      id: id ?? this.id,
      method: method ?? this.method,
      params: params ?? this.params,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcpRequest &&
          id == other.id &&
          method == other.method &&
          _mapEquals(params, other.params);

  @override
  int get hashCode => Object.hash(id, method, params);

  @override
  String toString() => 'AcpRequest(id: $id, method: $method, params: $params)';
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

bool _nullableMapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return _mapEquals(a, b);
}

// ============================================================================
// Request-specific parameter models
// ============================================================================

/// Client information for initialize request
class ClientInfo {
  final String id;
  final String name;
  final String version;
  final String platform;
  final String mode;

  const ClientInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.platform,
    this.mode = 'client',
  });

  ClientInfo copyWith({
    String? id,
    String? name,
    String? version,
    String? platform,
    String? mode,
  }) {
    return ClientInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      platform: platform ?? this.platform,
      mode: mode ?? this.mode,
    );
  }

  factory ClientInfo.fromJson(Map<String, dynamic> json) => ClientInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    version: json['version'] as String,
    platform: json['platform'] as String,
    mode: json['mode'] as String? ?? 'client',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'platform': platform,
    'mode': mode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientInfo &&
          id == other.id &&
          name == other.name &&
          version == other.version &&
          platform == other.platform &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(id, name, version, platform, mode);
}

/// Initialize request parameters
class InitializeParams {
  final int minProtocol;
  final int maxProtocol;
  final ClientInfo clientInfo;
  final Map<String, dynamic> capabilities;

  const InitializeParams({
    this.minProtocol = 3,
    this.maxProtocol = 3,
    required this.clientInfo,
    this.capabilities = const {},
  });

  InitializeParams copyWith({
    int? minProtocol,
    int? maxProtocol,
    ClientInfo? clientInfo,
    Map<String, dynamic>? capabilities,
  }) {
    return InitializeParams(
      minProtocol: minProtocol ?? this.minProtocol,
      maxProtocol: maxProtocol ?? this.maxProtocol,
      clientInfo: clientInfo ?? this.clientInfo,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  factory InitializeParams.fromJson(Map<String, dynamic> json) =>
      InitializeParams(
        minProtocol: json['minProtocol'] as int? ?? 3,
        maxProtocol: json['maxProtocol'] as int? ?? 3,
        clientInfo: ClientInfo.fromJson(
          json['clientInfo'] as Map<String, dynamic>,
        ),
        capabilities: json['capabilities'] as Map<String, dynamic>? ?? {},
      );

  Map<String, dynamic> toJson() => {
    'minProtocol': minProtocol,
    'maxProtocol': maxProtocol,
    'clientInfo': clientInfo.toJson(),
    'capabilities': capabilities,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitializeParams &&
          minProtocol == other.minProtocol &&
          maxProtocol == other.maxProtocol &&
          clientInfo == other.clientInfo &&
          _mapEquals(capabilities, other.capabilities);

  @override
  int get hashCode =>
      Object.hash(minProtocol, maxProtocol, clientInfo, capabilities);
}

/// Create session request parameters
class CreateSessionParams {
  final String? cwd;
  final Map<String, dynamic>? meta;
  final String? agentId;

  const CreateSessionParams({this.cwd, this.meta, this.agentId});

  CreateSessionParams copyWith({
    String? cwd,
    Map<String, dynamic>? meta,
    String? agentId,
  }) {
    return CreateSessionParams(
      cwd: cwd ?? this.cwd,
      meta: meta ?? this.meta,
      agentId: agentId ?? this.agentId,
    );
  }

  factory CreateSessionParams.fromJson(Map<String, dynamic> json) =>
      CreateSessionParams(
        cwd: json['cwd'] as String?,
        meta: json['meta'] as Map<String, dynamic>?,
        agentId: json['agentId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    if (cwd != null) 'cwd': cwd,
    if (meta != null) 'meta': meta,
    if (agentId != null) 'agentId': agentId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateSessionParams &&
          cwd == other.cwd &&
          _nullableMapEquals(meta, other.meta) &&
          agentId == other.agentId;

  @override
  int get hashCode => Object.hash(cwd, meta, agentId);
}

/// Prompt attachment for sendMessage
class PromptAttachment {
  final String type;
  final String mimeType;
  final String data;
  final int? width;
  final int? height;
  final int? duration;

  const PromptAttachment({
    required this.type,
    required this.mimeType,
    required this.data,
    this.width,
    this.height,
    this.duration,
  });

  PromptAttachment copyWith({
    String? type,
    String? mimeType,
    String? data,
    int? width,
    int? height,
    int? duration,
  }) {
    return PromptAttachment(
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      data: data ?? this.data,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
    );
  }

  factory PromptAttachment.fromJson(Map<String, dynamic> json) =>
      PromptAttachment(
        type: json['type'] as String,
        mimeType: json['mimeType'] as String,
        data: json['data'] as String,
        width: json['width'] as int?,
        height: json['height'] as int?,
        duration: json['duration'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'type': type,
    'mimeType': mimeType,
    'data': data,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (duration != null) 'duration': duration,
  };

  /// Create from ContentBlock
  factory PromptAttachment.fromContentBlock(ContentBlock block) {
    return switch (block) {
      TextContentBlock(:final text) => PromptAttachment(
        type: 'text',
        mimeType: 'text/plain',
        data: text,
      ),
      ImageContentBlock(
        :final mimeType,
        :final data,
        :final width,
        :final height,
      ) =>
        PromptAttachment(
          type: 'image',
          mimeType: mimeType,
          data: data,
          width: width,
          height: height,
        ),
      AudioContentBlock(:final mimeType, :final data, :final duration) =>
        PromptAttachment(
          type: 'audio',
          mimeType: mimeType,
          data: data,
          duration: duration,
        ),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptAttachment &&
          type == other.type &&
          mimeType == other.mimeType &&
          data == other.data &&
          width == other.width &&
          height == other.height &&
          duration == other.duration;

  @override
  int get hashCode =>
      Object.hash(type, mimeType, data, width, height, duration);
}

/// Prompt content for sendMessage request
class PromptContent {
  final String text;
  final List<PromptAttachment> attachments;

  const PromptContent({required this.text, this.attachments = const []});

  PromptContent copyWith({String? text, List<PromptAttachment>? attachments}) {
    return PromptContent(
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
    );
  }

  factory PromptContent.fromJson(Map<String, dynamic> json) => PromptContent(
    text: json['text'] as String,
    attachments:
        (json['attachments'] as List?)
            ?.map((e) => PromptAttachment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'attachments': attachments.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptContent &&
          text == other.text &&
          _listEquals(attachments, other.attachments);

  @override
  int get hashCode => Object.hash(text, attachments);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Send message (prompt) request parameters
class SendMessageParams {
  final String sessionId;
  final PromptContent prompt;

  const SendMessageParams({required this.sessionId, required this.prompt});

  SendMessageParams copyWith({String? sessionId, PromptContent? prompt}) {
    return SendMessageParams(
      sessionId: sessionId ?? this.sessionId,
      prompt: prompt ?? this.prompt,
    );
  }

  factory SendMessageParams.fromJson(Map<String, dynamic> json) =>
      SendMessageParams(
        sessionId: json['sessionId'] as String,
        prompt: PromptContent.fromJson(json['prompt'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'prompt': prompt.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendMessageParams &&
          sessionId == other.sessionId &&
          prompt == other.prompt;

  @override
  int get hashCode => Object.hash(sessionId, prompt);
}

/// End session request parameters
class EndSessionParams {
  final String sessionId;

  const EndSessionParams({required this.sessionId});

  EndSessionParams copyWith({String? sessionId}) {
    return EndSessionParams(sessionId: sessionId ?? this.sessionId);
  }

  factory EndSessionParams.fromJson(Map<String, dynamic> json) =>
      EndSessionParams(sessionId: json['sessionId'] as String);

  Map<String, dynamic> toJson() => {'sessionId': sessionId};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndSessionParams && sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

/// Cancel task request parameters
class CancelTaskParams {
  final String sessionId;
  final String? taskId;

  const CancelTaskParams({required this.sessionId, this.taskId});

  CancelTaskParams copyWith({String? sessionId, String? taskId}) {
    return CancelTaskParams(
      sessionId: sessionId ?? this.sessionId,
      taskId: taskId ?? this.taskId,
    );
  }

  factory CancelTaskParams.fromJson(Map<String, dynamic> json) =>
      CancelTaskParams(
        sessionId: json['sessionId'] as String,
        taskId: json['taskId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    if (taskId != null) 'taskId': taskId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelTaskParams &&
          sessionId == other.sessionId &&
          taskId == other.taskId;

  @override
  int get hashCode => Object.hash(sessionId, taskId);
}

/// Get agents request parameters (empty, but defined for consistency)
class GetAgentsParams {
  const GetAgentsParams();

  GetAgentsParams copyWith() => const GetAgentsParams();

  factory GetAgentsParams.fromJson(Map<String, dynamic> json) =>
      const GetAgentsParams();

  Map<String, dynamic> toJson() => {};
}

// ============================================================================
// Request factory methods
// ============================================================================

/// Factory for creating ACP requests
class AcpRequestFactory {
  AcpRequestFactory._();

  /// Generate a unique request ID
  static String generateId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Create initialize request
  static AcpRequest initialize({
    required String clientId,
    required String clientName,
    required String version,
    required String platform,
    int minProtocol = 3,
    int maxProtocol = 3,
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'initialize',
      params: InitializeParams(
        minProtocol: minProtocol,
        maxProtocol: maxProtocol,
        clientInfo: ClientInfo(
          id: clientId,
          name: clientName,
          version: version,
          platform: platform,
        ),
      ).toJson(),
    );
  }

  /// Create new session request
  static AcpRequest createSession({
    String? cwd,
    Map<String, dynamic>? meta,
    String? agentId,
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'newSession',
      params: CreateSessionParams(
        cwd: cwd,
        meta: meta,
        agentId: agentId,
      ).toJson(),
    );
  }

  /// Create send message (prompt) request
  static AcpRequest sendMessage({
    required String sessionId,
    required String text,
    List<PromptAttachment> attachments = const [],
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'prompt',
      params: SendMessageParams(
        sessionId: sessionId,
        prompt: PromptContent(text: text, attachments: attachments),
      ).toJson(),
    );
  }

  /// Create end session request
  static AcpRequest endSession({required String sessionId}) {
    return AcpRequest(
      id: generateId(),
      method: 'endSession',
      params: EndSessionParams(sessionId: sessionId).toJson(),
    );
  }

  /// Create cancel task request
  static AcpRequest cancelTask({required String sessionId, String? taskId}) {
    return AcpRequest(
      id: generateId(),
      method: 'cancel',
      params: CancelTaskParams(sessionId: sessionId, taskId: taskId).toJson(),
    );
  }

  /// Create get agents request
  static AcpRequest getAgents() {
    return AcpRequest(
      id: generateId(),
      method: 'listAgents',
      params: const GetAgentsParams().toJson(),
    );
  }

  /// Create list sessions request
  static AcpRequest listSessions({int? limit}) {
    return AcpRequest(
      id: generateId(),
      method: 'listSessions',
      params: {
        if (limit != null) '_meta': {'limit': limit},
      },
    );
  }
}
