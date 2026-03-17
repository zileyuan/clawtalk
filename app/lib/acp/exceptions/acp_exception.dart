/// Base exception for all ACP-related errors
abstract class AcpException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AcpException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when connection fails
class AcpConnectionException extends AcpException {
  final ConnectionErrorType errorType;

  const AcpConnectionException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.errorType = ConnectionErrorType.unknown,
  });

  factory AcpConnectionException.timeout([String? message]) {
    return AcpConnectionException(
      message ?? 'Connection timeout',
      code: 'CONNECTION_TIMEOUT',
      errorType: ConnectionErrorType.timeout,
    );
  }

  factory AcpConnectionException.refused([String? message]) {
    return AcpConnectionException(
      message ?? 'Connection refused',
      code: 'CONNECTION_REFUSED',
      errorType: ConnectionErrorType.refused,
    );
  }

  factory AcpConnectionException.networkError([String? message]) {
    return AcpConnectionException(
      message ?? 'Network error',
      code: 'NETWORK_ERROR',
      errorType: ConnectionErrorType.network,
    );
  }

  factory AcpConnectionException.authenticationFailed([String? message]) {
    return AcpConnectionException(
      message ?? 'Authentication failed',
      code: 'AUTH_FAILED',
      errorType: ConnectionErrorType.authentication,
    );
  }

  factory AcpConnectionException.sslError([String? message]) {
    return AcpConnectionException(
      message ?? 'SSL/TLS error',
      code: 'SSL_ERROR',
      errorType: ConnectionErrorType.ssl,
    );
  }
}

/// Connection error types
enum ConnectionErrorType {
  unknown,
  timeout,
  refused,
  network,
  authentication,
  ssl,
  dns,
  protocol,
}

/// Exception thrown for protocol errors
class AcpProtocolException extends AcpException {
  final ProtocolErrorType errorType;

  const AcpProtocolException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.errorType = ProtocolErrorType.unknown,
  });

  factory AcpProtocolException.invalidMessage([String? details]) {
    return AcpProtocolException(
      'Invalid message format${details != null ? ': $details' : ''}',
      code: 'INVALID_MESSAGE',
      errorType: ProtocolErrorType.invalidMessage,
    );
  }

  factory AcpProtocolException.unexpectedMessageType(String type) {
    return AcpProtocolException(
      'Unexpected message type: $type',
      code: 'UNEXPECTED_TYPE',
      errorType: ProtocolErrorType.unexpectedType,
    );
  }

  factory AcpProtocolException.missingField(String field) {
    return AcpProtocolException(
      'Missing required field: $field',
      code: 'MISSING_FIELD',
      errorType: ProtocolErrorType.missingField,
    );
  }

  factory AcpProtocolException.versionMismatch(String expected, String actual) {
    return AcpProtocolException(
      'Protocol version mismatch: expected $expected, got $actual',
      code: 'VERSION_MISMATCH',
      errorType: ProtocolErrorType.versionMismatch,
    );
  }
}

/// Protocol error types
enum ProtocolErrorType {
  unknown,
  invalidMessage,
  unexpectedType,
  missingField,
  versionMismatch,
  encodingError,
}

/// Exception thrown when operation times out
class AcpTimeoutException extends AcpException {
  final Duration? timeoutDuration;
  final String? operation;

  const AcpTimeoutException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.timeoutDuration,
    this.operation,
  });

  factory AcpTimeoutException.requestTimeout(
    String requestId,
    Duration duration,
  ) {
    return AcpTimeoutException(
      'Request $requestId timed out after ${duration.inSeconds}s',
      code: 'REQUEST_TIMEOUT',
      timeoutDuration: duration,
      operation: 'request',
    );
  }

  factory AcpTimeoutException.connectionTimeout(Duration duration) {
    return AcpTimeoutException(
      'Connection timed out after ${duration.inSeconds}s',
      code: 'CONNECTION_TIMEOUT',
      timeoutDuration: duration,
      operation: 'connect',
    );
  }

  factory AcpTimeoutException.heartbeatTimeout(Duration duration) {
    return AcpTimeoutException(
      'Heartbeat response timed out after ${duration.inSeconds}s',
      code: 'HEARTBEAT_TIMEOUT',
      timeoutDuration: duration,
      operation: 'heartbeat',
    );
  }
}

/// Exception thrown for serialization/deserialization errors
class AcpSerializationException extends AcpException {
  final SerializationErrorType errorType;

  const AcpSerializationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.errorType = SerializationErrorType.unknown,
  });

  factory AcpSerializationException.fromJson(
    String message, {
    dynamic originalError,
  }) {
    return AcpSerializationException(
      'JSON deserialization failed: $message',
      code: 'JSON_ERROR',
      originalError: originalError,
      errorType: SerializationErrorType.json,
    );
  }

  factory AcpSerializationException.toJson(
    String message, {
    dynamic originalError,
  }) {
    return AcpSerializationException(
      'JSON serialization failed: $message',
      code: 'JSON_ERROR',
      originalError: originalError,
      errorType: SerializationErrorType.json,
    );
  }

  factory AcpSerializationException.binary(String message) {
    return AcpSerializationException(
      'Binary serialization failed: $message',
      code: 'BINARY_ERROR',
      errorType: SerializationErrorType.binary,
    );
  }

  factory AcpSerializationException.unsupportedType(String type) {
    return AcpSerializationException(
      'Unsupported serialization type: $type',
      code: 'UNSUPPORTED_TYPE',
      errorType: SerializationErrorType.unsupportedType,
    );
  }
}

/// Serialization error types
enum SerializationErrorType {
  unknown,
  json,
  binary,
  unsupportedType,
  invalidEncoding,
}

/// Exception thrown when a request fails on the server
class AcpRequestException extends AcpException {
  final String requestId;

  const AcpRequestException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    required this.requestId,
  });

  factory AcpRequestException.notFound(String requestId, String resource) {
    return AcpRequestException(
      'Resource not found: $resource',
      code: 'NOT_FOUND',
      requestId: requestId,
    );
  }

  factory AcpRequestException.unauthorized(String requestId) {
    return AcpRequestException(
      'Unauthorized access',
      code: 'UNAUTHORIZED',
      requestId: requestId,
    );
  }

  factory AcpRequestException.forbidden(String requestId) {
    return AcpRequestException(
      'Access forbidden',
      code: 'FORBIDDEN',
      requestId: requestId,
    );
  }

  factory AcpRequestException.badRequest(String requestId, String details) {
    return AcpRequestException(
      'Bad request: $details',
      code: 'BAD_REQUEST',
      requestId: requestId,
    );
  }

  factory AcpRequestException.internalError(
    String requestId, [
    String? details,
  ]) {
    return AcpRequestException(
      'Internal server error${details != null ? ': $details' : ''}',
      code: 'INTERNAL_ERROR',
      requestId: requestId,
    );
  }
}

/// Exception thrown when client is not in a valid state for operation
class AcpStateException extends AcpException {
  final String currentState;
  final String expectedState;

  const AcpStateException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
    required this.currentState,
    required this.expectedState,
  });

  factory AcpStateException.notConnected() {
    return const AcpStateException(
      'Client is not connected',
      code: 'NOT_CONNECTED',
      currentState: 'disconnected',
      expectedState: 'connected',
    );
  }

  factory AcpStateException.alreadyConnected() {
    return const AcpStateException(
      'Client is already connected',
      code: 'ALREADY_CONNECTED',
      currentState: 'connected',
      expectedState: 'disconnected',
    );
  }

  factory AcpStateException.connecting() {
    return const AcpStateException(
      'Client is currently connecting',
      code: 'CONNECTING',
      currentState: 'connecting',
      expectedState: 'connected or disconnected',
    );
  }
}
