/// Base exception for Gateway protocol errors
sealed class GatewayException implements Exception {
  /// Error message
  final String message;

  /// Original error if any
  final Object? originalError;

  const GatewayException(this.message, {this.originalError});

  @override
  String toString() => 'GatewayException: $message';
}

/// Connection-related errors
class GatewayConnectionException extends GatewayException {
  const GatewayConnectionException(super.message, {super.originalError});

  factory GatewayConnectionException.timeout() =>
      const GatewayConnectionException('Connection timeout');

  factory GatewayConnectionException.refused() =>
      const GatewayConnectionException('Connection refused');

  factory GatewayConnectionException.failed(Object error) =>
      GatewayConnectionException(
        'Connection failed: $error',
        originalError: error,
      );

  @override
  String toString() => 'GatewayConnectionException: $message';
}

/// Handshake errors (challenge-response flow)
class GatewayHandshakeException extends GatewayException {
  const GatewayHandshakeException(super.message);

  factory GatewayHandshakeException.noChallenge() =>
      const GatewayHandshakeException(
        'Did not receive connect.challenge event within timeout',
      );

  factory GatewayHandshakeException.noHello() =>
      const GatewayHandshakeException(
        'Did not receive hello-ok response within timeout',
      );

  factory GatewayHandshakeException.invalidChallenge() =>
      const GatewayHandshakeException('Invalid challenge response');

  factory GatewayHandshakeException.authFailed(String reason) =>
      GatewayHandshakeException('Authentication failed: $reason');

  @override
  String toString() => 'GatewayHandshakeException: $message';
}

/// State errors
class GatewayStateException extends GatewayException {
  const GatewayStateException(super.message);

  factory GatewayStateException.notConnected() =>
      const GatewayStateException('Not connected to Gateway');

  factory GatewayStateException.alreadyConnected() =>
      const GatewayStateException('Already connected to Gateway');

  factory GatewayStateException.invalidState(String current, String expected) =>
      GatewayStateException('Invalid state: $current, expected: $expected');

  @override
  String toString() => 'GatewayStateException: $message';
}

/// Request/response errors
class GatewayRequestException extends GatewayException {
  /// Error code if provided
  final String? code;

  /// Request ID for correlation
  final String? requestId;

  const GatewayRequestException(
    super.message, {
    this.code,
    this.requestId,
    super.originalError,
  });

  factory GatewayRequestException.failed(
    String method,
    String error, {
    String? code,
    String? requestId,
  }) => GatewayRequestException(
    'Request $method failed: $error',
    code: code,
    requestId: requestId,
  );

  @override
  String toString() =>
      'GatewayRequestException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Timeout errors
class GatewayTimeoutException extends GatewayException {
  /// The timeout duration
  final Duration timeout;

  const GatewayTimeoutException(super.message, this.timeout);

  factory GatewayTimeoutException.request(String requestId, Duration timeout) =>
      GatewayTimeoutException(
        'Request $requestId timed out after ${timeout.inSeconds}s',
        timeout,
      );

  factory GatewayTimeoutException.handshake(Duration timeout) =>
      GatewayTimeoutException(
        'Handshake timed out after ${timeout.inSeconds}s',
        timeout,
      );

  @override
  String toString() => 'GatewayTimeoutException: $message';
}

/// Protocol errors
class GatewayProtocolException extends GatewayException {
  const GatewayProtocolException(super.message, {super.originalError});

  factory GatewayProtocolException.invalidMessage(Object data) =>
      GatewayProtocolException('Invalid message format: $data');

  factory GatewayProtocolException.unknownType(String type) =>
      GatewayProtocolException('Unknown message type: $type');

  factory GatewayProtocolException.parseError(Object error) =>
      GatewayProtocolException('Failed to parse message', originalError: error);

  @override
  String toString() => 'GatewayProtocolException: $message';
}
