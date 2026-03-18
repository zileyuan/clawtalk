import 'package:uuid/uuid.dart';

/// Base class for all ACP messages
abstract class AcpMessageBase {
  String get id;
  Map<String, dynamic> toJson();
}

/// ACP message types
enum AcpMessageType {
  request,
  response,
  notification,
  event,
  ping,
  pong,
  error,
}

/// Base ACP message
class AcpMessage implements AcpMessageBase {
  @override
  final String id;
  final AcpMessageType type;
  final Map<String, dynamic> payload;
  final DateTime? timestamp;

  const AcpMessage({
    required this.id,
    required this.type,
    required this.payload,
    this.timestamp,
  });

  AcpMessage copyWith({
    String? id,
    AcpMessageType? type,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
  }) {
    return AcpMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory AcpMessage.fromJson(Map<String, dynamic> json) {
    return AcpMessage(
      id: json['id'] as String,
      type: AcpMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AcpMessageType.error,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcpMessage) return false;
    return id == other.id &&
        type == other.type &&
        _mapEquals(payload, other.payload) &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode => Object.hash(id, type, payload, timestamp);
}

/// ACP Request message
class AcpRequest implements AcpMessageBase {
  @override
  final String id;
  final String method;
  final Map<String, dynamic>? params;
  final Map<String, dynamic> metadata;

  const AcpRequest({
    required this.id,
    required this.method,
    this.params,
    this.metadata = const {},
  });

  AcpRequest copyWith({
    String? id,
    String? method,
    Map<String, dynamic>? params,
    Map<String, dynamic>? metadata,
  }) {
    return AcpRequest(
      id: id ?? this.id,
      method: method ?? this.method,
      params: params ?? this.params,
      metadata: metadata ?? this.metadata,
    );
  }

  factory AcpRequest.fromJson(Map<String, dynamic> json) {
    return AcpRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'] as Map)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      if (params != null) 'params': params,
      'metadata': metadata,
    };
  }

  factory AcpRequest.create({
    String? id,
    required String method,
    Map<String, dynamic>? params,
  }) {
    return AcpRequest(
      id: id ?? const Uuid().v4(),
      method: method,
      params: params,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcpRequest) return false;
    return id == other.id &&
        method == other.method &&
        _mapEquals(params, other.params) &&
        _mapEquals(metadata, other.metadata);
  }

  @override
  int get hashCode => Object.hash(id, method, params, metadata);
}

/// ACP Response message
class AcpResponse implements AcpMessageBase {
  @override
  final String id;
  final String requestId;
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final String? errorCode;

  const AcpResponse({
    required this.id,
    required this.requestId,
    required this.success,
    this.data,
    this.error,
    this.errorCode,
  });

  AcpResponse copyWith({
    String? id,
    String? requestId,
    bool? success,
    Map<String, dynamic>? data,
    String? error,
    String? errorCode,
  }) {
    return AcpResponse(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      success: success ?? this.success,
      data: data ?? this.data,
      error: error ?? this.error,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  factory AcpResponse.fromJson(Map<String, dynamic> json) {
    return AcpResponse(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      success: json['success'] as bool,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      error: json['error'] as String?,
      errorCode: json['errorCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'success': success,
      if (data != null) 'data': data,
      if (error != null) 'error': error,
      if (errorCode != null) 'errorCode': errorCode,
    };
  }

  factory AcpResponse.success({
    required String requestId,
    Map<String, dynamic>? data,
  }) {
    return AcpResponse(
      id: const Uuid().v4(),
      requestId: requestId,
      success: true,
      data: data,
    );
  }

  factory AcpResponse.error({
    required String requestId,
    required String error,
    String? errorCode,
  }) {
    return AcpResponse(
      id: const Uuid().v4(),
      requestId: requestId,
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcpResponse) return false;
    return id == other.id &&
        requestId == other.requestId &&
        success == other.success &&
        _mapEquals(data, other.data) &&
        error == other.error &&
        errorCode == other.errorCode;
  }

  @override
  int get hashCode =>
      Object.hash(id, requestId, success, data, error, errorCode);
}

/// ACP Notification message (fire and forget)
class AcpNotification implements AcpMessageBase {
  @override
  final String id;
  final String event;
  final Map<String, dynamic>? payload;

  const AcpNotification({required this.id, required this.event, this.payload});

  AcpNotification copyWith({
    String? id,
    String? event,
    Map<String, dynamic>? payload,
  }) {
    return AcpNotification(
      id: id ?? this.id,
      event: event ?? this.event,
      payload: payload ?? this.payload,
    );
  }

  factory AcpNotification.fromJson(Map<String, dynamic> json) {
    return AcpNotification(
      id: json['id'] as String,
      event: json['event'] as String,
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'event': event, if (payload != null) 'payload': payload};
  }

  factory AcpNotification.create({
    String? id,
    required String event,
    Map<String, dynamic>? payload,
  }) {
    return AcpNotification(
      id: id ?? const Uuid().v4(),
      event: event,
      payload: payload,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcpNotification) return false;
    return id == other.id &&
        event == other.event &&
        _mapEquals(payload, other.payload);
  }

  @override
  int get hashCode => Object.hash(id, event, payload);
}

/// ACP Event message (incoming from server)
class AcpEvent implements AcpMessageBase {
  @override
  final String id;
  final String name;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const AcpEvent({
    required this.id,
    required this.name,
    this.data,
    required this.timestamp,
  });

  AcpEvent copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return AcpEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory AcpEvent.fromJson(Map<String, dynamic> json) {
    return AcpEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (data != null) 'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcpEvent) return false;
    return id == other.id &&
        name == other.name &&
        _mapEquals(data, other.data) &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode => Object.hash(id, name, data, timestamp);
}

/// ACP Ping message
class AcpPing {
  final String id;
  final DateTime timestamp;

  const AcpPing({required this.id, required this.timestamp});

  AcpPing copyWith({String? id, DateTime? timestamp}) {
    return AcpPing(id: id ?? this.id, timestamp: timestamp ?? this.timestamp);
  }

  factory AcpPing.fromJson(Map<String, dynamic> json) {
    return AcpPing(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'timestamp': timestamp.toIso8601String()};
  }

  factory AcpPing.create([String? id]) {
    return AcpPing(id: id ?? const Uuid().v4(), timestamp: DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcpPing) return false;
    return id == other.id && timestamp == other.timestamp;
  }

  @override
  int get hashCode => Object.hash(id, timestamp);
}

/// ACP Pong message
class AcpPong implements AcpMessageBase {
  @override
  final String id;
  final String pingId;
  final DateTime timestamp;

  const AcpPong({
    required this.id,
    required this.pingId,
    required this.timestamp,
  });

  AcpPong copyWith({String? id, String? pingId, DateTime? timestamp}) {
    return AcpPong(
      id: id ?? this.id,
      pingId: pingId ?? this.pingId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory AcpPong.fromJson(Map<String, dynamic> json) {
    return AcpPong(
      id: json['id'] as String,
      pingId: json['pingId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pingId': pingId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AcpPong.fromPing(AcpPing ping) {
    return AcpPong(
      id: const Uuid().v4(),
      pingId: ping.id,
      timestamp: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcpPong) return false;
    return id == other.id &&
        pingId == other.pingId &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode => Object.hash(id, pingId, timestamp);
}

/// Message serializer utility
class AcpMessageSerializer {
  /// Serialize a request to JSON
  static Map<String, dynamic> serializeRequest(AcpRequest request) {
    return {
      'type': 'request',
      'id': request.id,
      'method': request.method,
      if (request.params != null) 'params': request.params,
      'metadata': request.metadata,
    };
  }

  /// Serialize a notification to JSON
  static Map<String, dynamic> serializeNotification(
    AcpNotification notification,
  ) {
    return {
      'type': 'notification',
      'id': notification.id,
      'event': notification.event,
      if (notification.payload != null) 'payload': notification.payload,
    };
  }

  /// Serialize a ping to JSON
  static Map<String, dynamic> serializePing(AcpPing ping) {
    return {
      'type': 'ping',
      'id': ping.id,
      'timestamp': ping.timestamp.toIso8601String(),
    };
  }

  /// Serialize a pong to JSON
  static Map<String, dynamic> serializePong(AcpPong pong) {
    return {
      'type': 'pong',
      'id': pong.id,
      'pingId': pong.pingId,
      'timestamp': pong.timestamp.toIso8601String(),
    };
  }

  /// Deserialize a message from JSON
  static AcpMessageBase? deserialize(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'response':
        return AcpResponse.fromJson(json);
      case 'event':
        return AcpEvent.fromJson(json);
      case 'pong':
        return AcpPong.fromJson(json);
      case 'error':
        return AcpMessage.fromJson(json);
      default:
        return AcpMessage.fromJson(json);
    }
  }
}

/// Helper function to compare maps for equality
bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
