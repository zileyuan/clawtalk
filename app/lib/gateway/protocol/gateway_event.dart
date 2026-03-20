import 'gateway_message.dart';

/// Gateway event type constants
class GatewayEventType {
  // Connection events
  static const String connectChallenge = 'connect.challenge';

  // Chat events (Gateway uses 'chat' with state field)
  static const String chat = 'chat';

  // Message events (legacy/alternative format)
  static const String message = 'message';
  static const String messageStart = 'message.start';
  static const String messageDelta = 'message.delta';
  static const String messageEnd = 'message.end';

  // Tool events
  static const String toolCall = 'tool_call';
  static const String toolCallStart = 'tool_call.start';
  static const String toolCallDelta = 'tool_call.delta';
  static const String toolCallEnd = 'tool_call.end';

  // Session events
  static const String sessionUpdate = 'session.update';
  static const String sessionInfo = 'session_info_update';

  // Usage events
  static const String usage = 'usage';

  // Completion events
  static const String done = 'done';
  static const String error = 'error';

  // System events
  static const String tick = 'tick';
  static const String health = 'health';
  static const String presence = 'presence';

  // Prevent instantiation
  GatewayEventType._();
}

/// Gateway event message (server -> client)
class GatewayEvent implements GatewayMessage {
  @override
  String get type => GatewayMessageType.event.name;

  @override
  final String id;

  final String event;
  final Map<String, dynamic>? payload;
  final int? seq;
  final Map<String, dynamic>? stateVersion;
  final DateTime? timestamp;

  GatewayEvent({
    String? id,
    required this.event,
    this.payload,
    this.seq,
    this.stateVersion,
    this.timestamp,
  }) : id = id ?? 'evt_${DateTime.now().microsecondsSinceEpoch}';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'event': event,
    if (payload != null) 'payload': payload,
    if (seq != null) 'seq': seq,
    if (stateVersion != null) 'stateVersion': stateVersion,
  };

  factory GatewayEvent.fromJson(Map<String, dynamic> json) => GatewayEvent(
    id: json['id'] as String?,
    event: json['event'] as String,
    payload: json['payload'] as Map<String, dynamic>?,
    seq: json['seq'] as int?,
    stateVersion: json['stateVersion'] as Map<String, dynamic>?,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : null,
  );

  /// Check if this is a specific event type
  bool isType(String eventType) => event == eventType;

  /// Get typed payload
  T? payloadAs<T>() => payload as T?;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GatewayEvent &&
          event == other.event &&
          _mapEquals(payload, other.payload) &&
          seq == other.seq;

  @override
  int get hashCode => Object.hash(event, payload, seq);
}

// ============================================================================
// Event Payload Types
// ============================================================================

/// Challenge event payload (connect.challenge)
class ChallengePayload {
  final String nonce;
  final DateTime timestamp;

  const ChallengePayload({required this.nonce, required this.timestamp});

  factory ChallengePayload.fromJson(Map<String, dynamic> json) =>
      ChallengePayload(
        nonce: json['nonce'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );

  Map<String, dynamic> toJson() => {
    'nonce': nonce,
    'ts': timestamp.millisecondsSinceEpoch,
  };
}

/// Server features (from hello-ok response)
class ServerFeatures {
  final List<String> methods;
  final List<String> events;

  const ServerFeatures({required this.methods, required this.events});

  factory ServerFeatures.fromJson(Map<String, dynamic> json) => ServerFeatures(
    methods: (json['methods'] as List?)?.cast<String>() ?? [],
    events: (json['events'] as List?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> toJson() => {'methods': methods, 'events': events};

  bool hasMethod(String method) => methods.contains(method);
  bool hasEvent(String event) => events.contains(event);
}

/// Hello-ok response payload
class HelloOkPayload {
  final int protocol;
  final ServerFeatures features;
  final String? serverConnId;
  final Map<String, dynamic>? policy;
  final String? canvasHostUrl;

  const HelloOkPayload({
    required this.protocol,
    required this.features,
    this.serverConnId,
    this.policy,
    this.canvasHostUrl,
  });

  factory HelloOkPayload.fromJson(Map<String, dynamic> json) => HelloOkPayload(
    protocol: json['protocol'] as int? ?? 3,
    features: json['features'] != null
        ? ServerFeatures.fromJson(json['features'] as Map<String, dynamic>)
        : const ServerFeatures(methods: [], events: []),
    serverConnId: json['serverConnId'] as String?,
    policy: json['policy'] as Map<String, dynamic>?,
    canvasHostUrl: json['canvasHostUrl'] as String?,
  );
}

/// Message content part
class MessageContentPart {
  final String type; // 'text', 'image', etc.
  final String? text;
  final String? mimeType;
  final String? data;

  const MessageContentPart({
    required this.type,
    this.text,
    this.mimeType,
    this.data,
  });

  factory MessageContentPart.fromJson(Map<String, dynamic> json) =>
      MessageContentPart(
        type: json['type'] as String,
        text: json['text'] as String?,
        mimeType: json['mimeType'] as String?,
        data: json['data'] as String?,
      );

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
}

/// Message event payload
class MessagePayload {
  final String sessionId;
  final String role; // 'user', 'assistant', 'system'
  final List<MessageContentPart> content;
  final String? stopReason;

  const MessagePayload({
    required this.sessionId,
    required this.role,
    required this.content,
    this.stopReason,
  });

  factory MessagePayload.fromJson(Map<String, dynamic> json) => MessagePayload(
    sessionId: json['sessionId'] as String,
    role: json['role'] as String,
    content:
        (json['content'] as List?)
            ?.map((e) => MessageContentPart.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    stopReason: json['stopReason'] as String?,
  );

  String? get textContent => content
      .where((c) => c.isText)
      .map((c) => c.text)
      .whereType<String>()
      .join('\n');
}

/// Tool call event payload
class ToolCallPayload {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic>? input;
  final Map<String, dynamic>? output;
  final String? status; // 'pending', 'running', 'complete', 'error'

  const ToolCallPayload({
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.output,
    this.status,
  });

  factory ToolCallPayload.fromJson(Map<String, dynamic> json) =>
      ToolCallPayload(
        toolCallId: json['toolCallId'] as String,
        toolName: json['toolName'] as String,
        input: json['input'] as Map<String, dynamic>?,
        output: json['output'] as Map<String, dynamic>?,
        status: json['status'] as String?,
      );
}

/// Usage event payload
class UsagePayload {
  final int inputTokens;
  final int outputTokens;
  final int? cacheWriteTokens;
  final int? cacheReadTokens;

  const UsagePayload({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheWriteTokens,
    this.cacheReadTokens,
  });

  factory UsagePayload.fromJson(Map<String, dynamic> json) => UsagePayload(
    inputTokens: json['inputTokens'] as int? ?? 0,
    outputTokens: json['outputTokens'] as int? ?? 0,
    cacheWriteTokens: json['cacheWriteTokens'] as int?,
    cacheReadTokens: json['cacheReadTokens'] as int?,
  );

  int get totalTokens => inputTokens + outputTokens;
}

/// Done event payload
class DonePayload {
  final String sessionId;
  final String? stopReason;
  final UsagePayload? usage;

  const DonePayload({required this.sessionId, this.stopReason, this.usage});

  factory DonePayload.fromJson(Map<String, dynamic> json) => DonePayload(
    sessionId: json['sessionId'] as String,
    stopReason: json['stopReason'] as String?,
    usage: json['usage'] != null
        ? UsagePayload.fromJson(json['usage'] as Map<String, dynamic>)
        : null,
  );
}

/// Error event payload
class ErrorPayload {
  final String? code;
  final String message;
  final String? sessionId;
  final Map<String, dynamic>? details;

  const ErrorPayload({
    this.code,
    required this.message,
    this.sessionId,
    this.details,
  });

  factory ErrorPayload.fromJson(Map<String, dynamic> json) => ErrorPayload(
    code: json['code'] as String?,
    message:
        json['message'] as String? ??
        json['error'] as String? ??
        'Unknown error',
    sessionId: json['sessionId'] as String?,
    details: json['details'] as Map<String, dynamic>?,
  );
}

/// Tick event payload (heartbeat)
class TickPayload {
  final DateTime timestamp;

  const TickPayload({required this.timestamp});

  factory TickPayload.fromJson(Map<String, dynamic> json) => TickPayload(
    timestamp: json['ts'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['ts'] as int)
        : DateTime.now(),
  );
}

// Helper function
bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
