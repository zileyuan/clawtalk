import 'gateway_message.dart';

/// Gateway response error shape
class GatewayError {
  /// Error code (e.g., 'AUTH_TOKEN_MISMATCH')
  final String? code;

  /// Error message
  final String message;

  /// Additional error details
  final Map<String, dynamic>? details;

  const GatewayError({this.code, required this.message, this.details});

  factory GatewayError.fromJson(Map<String, dynamic> json) => GatewayError(
    code: json['code'] as String?,
    message:
        json['message'] as String? ??
        json['error'] as String? ??
        'Unknown error',
    details: json['details'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    if (code != null) 'code': code,
    'message': message,
    if (details != null) 'details': details,
  };

  @override
  String toString() => 'GatewayError(${code ?? 'unknown'}: $message)';
}

/// Gateway response message (server -> client)
class GatewayResponse implements GatewayMessage {
  @override
  final String id;

  @override
  String get type => GatewayMessageType.response.name;

  /// Whether the request was successful
  final bool ok;

  /// Response payload (present on success)
  final Map<String, dynamic>? payload;

  /// Error details (present on failure)
  final GatewayError? error;

  GatewayResponse({
    required this.id,
    required this.ok,
    this.payload,
    this.error,
  });

  /// Create from JSON
  factory GatewayResponse.fromJson(Map<String, dynamic> json) =>
      GatewayResponse(
        id: json['id'] as String,
        ok: json['ok'] as bool,
        payload: json['payload'] as Map<String, dynamic>?,
        error: json['error'] != null
            ? GatewayError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'ok': ok,
    if (payload != null) 'payload': payload,
    if (error != null) 'error': error!.toJson(),
  };

  /// Create a successful response
  factory GatewayResponse.success({
    required String id,
    Map<String, dynamic>? payload,
  }) => GatewayResponse(id: id, ok: true, payload: payload);

  /// Create an error response
  factory GatewayResponse.error({
    required String id,
    required String message,
    String? code,
  }) => GatewayResponse(
    id: id,
    ok: false,
    error: GatewayError(code: code, message: message),
  );

  /// Check if response has a specific error code
  bool hasErrorCode(String errorCode) => error?.code == errorCode;

  /// Get payload value at path
  T? getPayload<T>(String key) => payload?[key] as T?;

  /// Copy with new values
  GatewayResponse copyWith({
    String? id,
    bool? ok,
    Map<String, dynamic>? payload,
    GatewayError? error,
  }) => GatewayResponse(
    id: id ?? this.id,
    ok: ok ?? this.ok,
    payload: payload ?? this.payload,
    error: error ?? this.error,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GatewayResponse &&
          id == other.id &&
          ok == other.ok &&
          _mapEquals(payload, other.payload) &&
          error == other.error;

  @override
  int get hashCode => Object.hash(id, ok, payload, error);

  @override
  String toString() =>
      'GatewayResponse(id: $id, ok: $ok, ${ok ? 'payload: $payload' : 'error: $error'})';
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
