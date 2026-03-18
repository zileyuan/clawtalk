import 'acp_message.dart';
import 'content_block.dart';

/// ACP Event message type
///
/// Events are server-pushed messages that notify the client about state changes,
/// incoming messages, task progress, etc.
class AcpEvent extends AcpMessage {
  /// Event name/type
  final String event;

  /// Event payload data
  final Map<String, dynamic> payload;

  /// Sequence number for ordered events
  final int? seq;

  /// State version for synchronization
  final int? stateVersion;

  const AcpEvent({
    required this.event,
    required this.payload,
    this.seq,
    this.stateVersion,
  });

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

  AcpEvent copyWith({
    String? event,
    Map<String, dynamic>? payload,
    int? seq,
    int? stateVersion,
  }) {
    return AcpEvent(
      event: event ?? this.event,
      payload: payload ?? this.payload,
      seq: seq ?? this.seq,
      stateVersion: stateVersion ?? this.stateVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcpEvent &&
          event == other.event &&
          _mapEquals(payload, other.payload) &&
          seq == other.seq &&
          stateVersion == other.stateVersion;

  @override
  int get hashCode => Object.hash(event, payload, seq, stateVersion);

  @override
  String toString() =>
      'AcpEvent(event: $event, payload: $payload, seq: $seq, '
      'stateVersion: $stateVersion)';
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
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
class MessageEventPayload {
  final String sessionId;
  final String messageId;
  final String role;
  final List<ContentBlock> content;
  final DateTime? timestamp;

  const MessageEventPayload({
    required this.sessionId,
    required this.messageId,
    required this.role,
    required this.content,
    this.timestamp,
  });

  factory MessageEventPayload.fromJson(Map<String, dynamic> json) =>
      MessageEventPayload(
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        role: json['role'] as String,
        content: (json['content'] as List)
            .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'messageId': messageId,
    'role': role,
    'content': content.map((e) => e.toJson()).toList(),
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };

  MessageEventPayload copyWith({
    String? sessionId,
    String? messageId,
    String? role,
    List<ContentBlock>? content,
    DateTime? timestamp,
  }) {
    return MessageEventPayload(
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageEventPayload &&
          sessionId == other.sessionId &&
          messageId == other.messageId &&
          role == other.role &&
          _listEquals(content, other.content) &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      Object.hash(sessionId, messageId, role, content, timestamp);

  @override
  String toString() =>
      'MessageEventPayload(sessionId: $sessionId, messageId: $messageId, '
      'role: $role, content: $content, timestamp: $timestamp)';
}

bool _listEquals(List<ContentBlock> a, List<ContentBlock> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Tool call status
enum ToolCallStatus {
  pending,
  running,
  completed,
  failed;

  String toJson() => switch (this) {
    pending => 'pending',
    running => 'running',
    completed => 'completed',
    failed => 'failed',
  };

  static ToolCallStatus fromJson(String value) => switch (value) {
    'pending' => pending,
    'running' => running,
    'completed' => completed,
    'failed' => failed,
    _ => pending,
  };

  static ToolCallStatus fromString(String value) {
    return ToolCallStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ToolCallStatus.pending,
    );
  }
}

/// Tool call event payload
class ToolCallEventPayload {
  final String id;
  final String name;
  final ToolCallStatus status;
  final Map<String, dynamic>? input;
  final Map<String, dynamic>? output;
  final String? error;

  const ToolCallEventPayload({
    required this.id,
    required this.name,
    required this.status,
    this.input,
    this.output,
    this.error,
  });

  factory ToolCallEventPayload.fromJson(Map<String, dynamic> json) =>
      ToolCallEventPayload(
        id: json['id'] as String,
        name: json['name'] as String,
        status: ToolCallStatus.fromJson(json['status'] as String),
        input: json['input'] as Map<String, dynamic>?,
        output: json['output'] as Map<String, dynamic>?,
        error: json['error'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status.toJson(),
    if (input != null) 'input': input,
    if (output != null) 'output': output,
    if (error != null) 'error': error,
  };

  ToolCallEventPayload copyWith({
    String? id,
    String? name,
    ToolCallStatus? status,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    String? error,
  }) {
    return ToolCallEventPayload(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      input: input ?? this.input,
      output: output ?? this.output,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolCallEventPayload &&
          id == other.id &&
          name == other.name &&
          status == other.status &&
          _nullableMapEquals(input, other.input) &&
          _nullableMapEquals(output, other.output) &&
          error == other.error;

  @override
  int get hashCode => Object.hash(id, name, status, input, output, error);

  @override
  String toString() =>
      'ToolCallEventPayload(id: $id, name: $name, status: $status, '
      'input: $input, output: $output, error: $error)';
}

bool _nullableMapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return _mapEquals(a, b);
}

/// Usage information for tokens
class UsageInfo {
  final int inputTokens;
  final int outputTokens;
  final int? totalTokens;
  final int? cacheReadTokens;
  final int? cacheWriteTokens;

  const UsageInfo({
    required this.inputTokens,
    required this.outputTokens,
    this.totalTokens,
    this.cacheReadTokens,
    this.cacheWriteTokens,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
    inputTokens: json['inputTokens'] as int,
    outputTokens: json['outputTokens'] as int,
    totalTokens: json['totalTokens'] as int?,
    cacheReadTokens: json['cacheReadTokens'] as int?,
    cacheWriteTokens: json['cacheWriteTokens'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    if (totalTokens != null) 'totalTokens': totalTokens,
    if (cacheReadTokens != null) 'cacheReadTokens': cacheReadTokens,
    if (cacheWriteTokens != null) 'cacheWriteTokens': cacheWriteTokens,
  };

  UsageInfo copyWith({
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
  }) {
    return UsageInfo(
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageInfo &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          totalTokens == other.totalTokens &&
          cacheReadTokens == other.cacheReadTokens &&
          cacheWriteTokens == other.cacheWriteTokens;

  @override
  int get hashCode => Object.hash(
    inputTokens,
    outputTokens,
    totalTokens,
    cacheReadTokens,
    cacheWriteTokens,
  );

  @override
  String toString() =>
      'UsageInfo(inputTokens: $inputTokens, outputTokens: $outputTokens, '
      'totalTokens: $totalTokens, cacheReadTokens: $cacheReadTokens, '
      'cacheWriteTokens: $cacheWriteTokens)';
}

/// Done event payload
class DoneEventPayload {
  final String sessionId;
  final String? reason;
  final UsageInfo? usage;

  const DoneEventPayload({required this.sessionId, this.reason, this.usage});

  factory DoneEventPayload.fromJson(Map<String, dynamic> json) =>
      DoneEventPayload(
        sessionId: json['sessionId'] as String,
        reason: json['reason'] as String?,
        usage: json['usage'] != null
            ? UsageInfo.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    if (reason != null) 'reason': reason,
    if (usage != null) 'usage': usage!.toJson(),
  };

  DoneEventPayload copyWith({
    String? sessionId,
    String? reason,
    UsageInfo? usage,
  }) {
    return DoneEventPayload(
      sessionId: sessionId ?? this.sessionId,
      reason: reason ?? this.reason,
      usage: usage ?? this.usage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoneEventPayload &&
          sessionId == other.sessionId &&
          reason == other.reason &&
          usage == other.usage;

  @override
  int get hashCode => Object.hash(sessionId, reason, usage);

  @override
  String toString() =>
      'DoneEventPayload(sessionId: $sessionId, reason: $reason, usage: $usage)';
}

/// Session info update event payload
class SessionInfoUpdatePayload {
  final String sessionId;
  final String? status;
  final Map<String, dynamic>? changes;

  const SessionInfoUpdatePayload({
    required this.sessionId,
    this.status,
    this.changes,
  });

  factory SessionInfoUpdatePayload.fromJson(Map<String, dynamic> json) =>
      SessionInfoUpdatePayload(
        sessionId: json['sessionId'] as String,
        status: json['status'] as String?,
        changes: json['changes'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    if (status != null) 'status': status,
    if (changes != null) 'changes': changes,
  };

  SessionInfoUpdatePayload copyWith({
    String? sessionId,
    String? status,
    Map<String, dynamic>? changes,
  }) {
    return SessionInfoUpdatePayload(
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      changes: changes ?? this.changes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionInfoUpdatePayload &&
          sessionId == other.sessionId &&
          status == other.status &&
          _nullableMapEquals(changes, other.changes);

  @override
  int get hashCode => Object.hash(sessionId, status, changes);

  @override
  String toString() =>
      'SessionInfoUpdatePayload(sessionId: $sessionId, status: $status, '
      'changes: $changes)';
}

/// Usage update event payload
class UsageUpdatePayload {
  final String sessionId;
  final UsageInfo usage;

  const UsageUpdatePayload({required this.sessionId, required this.usage});

  factory UsageUpdatePayload.fromJson(Map<String, dynamic> json) =>
      UsageUpdatePayload(
        sessionId: json['sessionId'] as String,
        usage: UsageInfo.fromJson(json['usage'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'usage': usage.toJson(),
  };

  UsageUpdatePayload copyWith({String? sessionId, UsageInfo? usage}) {
    return UsageUpdatePayload(
      sessionId: sessionId ?? this.sessionId,
      usage: usage ?? this.usage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageUpdatePayload &&
          sessionId == other.sessionId &&
          usage == other.usage;

  @override
  int get hashCode => Object.hash(sessionId, usage);

  @override
  String toString() =>
      'UsageUpdatePayload(sessionId: $sessionId, usage: $usage)';
}

/// Error event payload
class ErrorEventPayload {
  final String? sessionId;
  final String? messageId;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const ErrorEventPayload({
    this.sessionId,
    this.messageId,
    required this.code,
    required this.message,
    this.details,
  });

  factory ErrorEventPayload.fromJson(Map<String, dynamic> json) =>
      ErrorEventPayload(
        sessionId: json['sessionId'] as String?,
        messageId: json['messageId'] as String?,
        code: json['code'] as String,
        message: json['message'] as String,
        details: json['details'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
    if (sessionId != null) 'sessionId': sessionId,
    if (messageId != null) 'messageId': messageId,
    'code': code,
    'message': message,
    if (details != null) 'details': details,
  };

  ErrorEventPayload copyWith({
    String? sessionId,
    String? messageId,
    String? code,
    String? message,
    Map<String, dynamic>? details,
  }) {
    return ErrorEventPayload(
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
      code: code ?? this.code,
      message: message ?? this.message,
      details: details ?? this.details,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorEventPayload &&
          sessionId == other.sessionId &&
          messageId == other.messageId &&
          code == other.code &&
          message == other.message &&
          _nullableMapEquals(details, other.details);

  @override
  int get hashCode => Object.hash(sessionId, messageId, code, message, details);

  @override
  String toString() =>
      'ErrorEventPayload(sessionId: $sessionId, messageId: $messageId, '
      'code: $code, message: $message, details: $details)';
}

/// Status event payload
class StatusEventPayload {
  final String status;
  final String? message;
  final Map<String, dynamic>? data;

  const StatusEventPayload({required this.status, this.message, this.data});

  factory StatusEventPayload.fromJson(Map<String, dynamic> json) =>
      StatusEventPayload(
        status: json['status'] as String,
        message: json['message'] as String?,
        data: json['data'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    if (message != null) 'message': message,
    if (data != null) 'data': data,
  };

  StatusEventPayload copyWith({
    String? status,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return StatusEventPayload(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusEventPayload &&
          status == other.status &&
          message == other.message &&
          _nullableMapEquals(data, other.data);

  @override
  int get hashCode => Object.hash(status, message, data);

  @override
  String toString() =>
      'StatusEventPayload(status: $status, message: $message, data: $data)';
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
