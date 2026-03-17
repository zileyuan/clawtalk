import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'acp_message.freezed.dart';
part 'acp_message.g.dart';

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
@freezed
class AcpMessage with _$AcpMessage {
  const factory AcpMessage({
    required String id,
    required AcpMessageType type,
    required Map<String, dynamic> payload,
    DateTime? timestamp,
  }) = _AcpMessage;

  factory AcpMessage.fromJson(Map<String, dynamic> json) =>
      _$AcpMessageFromJson(json);
}

/// ACP Request message
@freezed
class AcpRequest with _$AcpRequest {
  const factory AcpRequest({
    required String id,
    required String method,
    Map<String, dynamic>? params,
    @Default({}) Map<String, dynamic> metadata,
  }) = _AcpRequest;

  factory AcpRequest.fromJson(Map<String, dynamic> json) =>
      _$AcpRequestFromJson(json);

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
}

/// ACP Response message
@freezed
class AcpResponse with _$AcpResponse {
  const factory AcpResponse({
    required String id,
    required String requestId,
    required bool success,
    Map<String, dynamic>? data,
    String? error,
    String? errorCode,
  }) = _AcpResponse;

  factory AcpResponse.fromJson(Map<String, dynamic> json) =>
      _$AcpResponseFromJson(json);

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
}

/// ACP Notification message (fire and forget)
@freezed
class AcpNotification with _$AcpNotification {
  const factory AcpNotification({
    required String id,
    required String event,
    Map<String, dynamic>? payload,
  }) = _AcpNotification;

  factory AcpNotification.fromJson(Map<String, dynamic> json) =>
      _$AcpNotificationFromJson(json);

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
}

/// ACP Event message (incoming from server)
@freezed
class AcpEvent with _$AcpEvent {
  const factory AcpEvent({
    required String id,
    required String name,
    Map<String, dynamic>? data,
    required DateTime timestamp,
  }) = _AcpEvent;

  factory AcpEvent.fromJson(Map<String, dynamic> json) =>
      _$AcpEventFromJson(json);
}

/// ACP Ping message
@freezed
class AcpPing with _$AcpPing {
  const factory AcpPing({required String id, required DateTime timestamp}) =
      _AcpPing;

  factory AcpPing.fromJson(Map<String, dynamic> json) =>
      _$AcpPingFromJson(json);

  factory AcpPing.create([String? id]) {
    return AcpPing(id: id ?? const Uuid().v4(), timestamp: DateTime.now());
  }
}

/// ACP Pong message
@freezed
class AcpPong with _$AcpPong {
  const factory AcpPong({
    required String id,
    required String pingId,
    required DateTime timestamp,
  }) = _AcpPong;

  factory AcpPong.fromJson(Map<String, dynamic> json) =>
      _$AcpPongFromJson(json);

  factory AcpPong.fromPing(AcpPing ping) {
    return AcpPong(
      id: const Uuid().v4(),
      pingId: ping.id,
      timestamp: DateTime.now(),
    );
  }
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
  static AcpMessage? deserialize(Map<String, dynamic> json) {
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
