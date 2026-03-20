import 'package:clawtalk/gateway/crypto/device_identity.dart';
import 'package:clawtalk/gateway/protocol/gateway_message.dart';
import 'package:uuid/uuid.dart';

/// Gateway request message
class GatewayRequest implements GatewayMessage {
  @override
  String get type => 'req'; // Gateway Protocol uses "req", not "request"

  @override
  final String id;
  final String method;
  final Map<String, dynamic>? params;

  const GatewayRequest({required this.id, required this.method, this.params});

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'method': method,
    if (params != null) 'params': params,
  };

  factory GatewayRequest.fromJson(Map<String, dynamic> json) => GatewayRequest(
    id: json['id'] as String,
    method: json['method'] as String,
    params: json['params'] as Map<String, dynamic>?,
  );

  /// Create a new request with auto-generated ID
  factory GatewayRequest.create({
    required String method,
    Map<String, dynamic>? params,
  }) => GatewayRequest(id: const Uuid().v4(), method: method, params: params);

  GatewayRequest copyWith({
    String? id,
    String? method,
    Map<String, dynamic>? params,
  }) => GatewayRequest(
    id: id ?? this.id,
    method: method ?? this.method,
    params: params ?? this.params,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GatewayRequest &&
          id == other.id &&
          method == other.method &&
          _mapEquals(params, other.params);

  @override
  int get hashCode => Object.hash(id, method, params);
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

/// Factory for creating Gateway requests
class GatewayRequestFactory {
  GatewayRequestFactory._();

  static String _generateId() => 'req_${DateTime.now().millisecondsSinceEpoch}';

  /// Create connect request (after receiving challenge)
  static GatewayRequest connect({
    required String nonce,
    String? token,
    String? password,
    String? clientId,
    String? clientVersion,
    String? displayName,
    String platform = 'macos',
    String mode =
        'ui', // "cli", "webchat", "ui", "backend", "node", "probe", "test"
    DeviceSignaturePayload? deviceSignature,
  }) => GatewayRequest(
    id: _generateId(),
    method: 'connect',
    params: {
      'minProtocol': 3,
      'maxProtocol': 3,
      'client': {
        'id':
            clientId ??
            'cli', // Use "cli" for CLI client (may bypass device auth)
        'version': clientVersion ?? '1.0.0',
        'platform': platform,
        'mode': mode,
        if (displayName != null) 'displayName': displayName,
      },
      'role': 'operator',
      'scopes': ['operator.read', 'operator.write'],
      'caps': <String>[],
      'commands': <String>[],
      'permissions': <String, dynamic>{},
      if (deviceSignature != null) 'device': deviceSignature.toJson(),
      if (token != null) 'auth': {'token': token},
      if (password != null && token == null) 'auth': {'password': password},
    },
  );

  /// Send a chat message
  ///
  /// Gateway expects:
  /// - sessionKey: The session key (e.g., "agent:main:main")
  /// - message: The message content
  /// - idempotencyKey: Unique key for idempotency
  static GatewayRequest chatSend({
    required String sessionKey,
    required String text,
    String? idempotencyKey,
  }) => GatewayRequest(
    id: _generateId(),
    method: 'chat.send',
    params: {
      'sessionKey': sessionKey,
      'message': text,
      'idempotencyKey': idempotencyKey ?? _generateId(),
    },
  );

  /// Abort a chat session
  static GatewayRequest chatAbort({required String sessionKey}) =>
      GatewayRequest(
        id: _generateId(),
        method: 'chat.abort',
        params: {'sessionKey': sessionKey},
      );

  /// Get chat history
  static GatewayRequest chatHistory({required String sessionKey, int? limit}) =>
      GatewayRequest(
        id: _generateId(),
        method: 'chat.history',
        params: {'sessionKey': sessionKey, if (limit != null) 'limit': limit},
      );

  /// List available agents
  static GatewayRequest agentsList() =>
      GatewayRequest(id: _generateId(), method: 'agents.list');

  /// List sessions
  static GatewayRequest sessionsList({int? limit, String? agentId}) =>
      GatewayRequest(
        id: _generateId(),
        method: 'sessions.list',
        params: {
          if (limit != null) 'limit': limit,
          if (agentId != null) 'agentId': agentId,
        },
      );

  /// Preview a session
  static GatewayRequest sessionsPreview({
    required String sessionKey,
    int? messageLimit,
  }) => GatewayRequest(
    id: _generateId(),
    method: 'sessions.preview',
    params: {
      'sessionKey': sessionKey,
      if (messageLimit != null) 'messageLimit': messageLimit,
    },
  );

  /// Reset a session
  static GatewayRequest sessionsReset({required String sessionKey}) =>
      GatewayRequest(
        id: _generateId(),
        method: 'sessions.reset',
        params: {'sessionKey': sessionKey},
      );

  /// Delete a session
  static GatewayRequest sessionsDelete({required String sessionKey}) =>
      GatewayRequest(
        id: _generateId(),
        method: 'sessions.delete',
        params: {'sessionKey': sessionKey},
      );

  /// Compact a session
  static GatewayRequest sessionsCompact({
    required String sessionKey,
    String? instructions,
  }) => GatewayRequest(
    id: _generateId(),
    method: 'sessions.compact',
    params: {
      'sessionKey': sessionKey,
      if (instructions != null) 'instructions': instructions,
    },
  );

  /// List available models
  static GatewayRequest modelsList() =>
      GatewayRequest(id: _generateId(), method: 'models.list');

  /// Get tools catalog
  static GatewayRequest toolsCatalog({String? agentId}) => GatewayRequest(
    id: _generateId(),
    method: 'tools.catalog',
    params: {if (agentId != null) 'agentId': agentId},
  );

  /// Get channels status
  static GatewayRequest channelsStatus() =>
      GatewayRequest(id: _generateId(), method: 'channels.status');

  /// Get gateway health
  static GatewayRequest healthGet() =>
      GatewayRequest(id: _generateId(), method: 'health.get');

  /// Get presence info
  static GatewayRequest presenceGet() =>
      GatewayRequest(id: _generateId(), method: 'presence.get');
}
