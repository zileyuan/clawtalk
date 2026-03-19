import 'package:clawtalk/gateway/protocol/gateway_event.dart';

/// Gateway connection status enum
/// Adds new states for challenge-response handshake
enum GatewayConnectionStatus {
  /// Not connected to any server
  disconnected,

  /// Currently attempting to establish WebSocket connection
  connecting,

  /// WebSocket connected, waiting for challenge event (NEW)
  awaitingChallenge,

  /// Challenge received, sending connect request (NEW)
  authenticating,

  /// Successfully connected and authenticated
  connected,

  /// Currently disconnecting from the server
  disconnecting,

  /// Connection encountered an error
  error,

  /// Connection lost, attempting to reconnect
  reconnecting,
}

/// Gateway connection state model
class GatewayConnectionState {
  final GatewayConnectionStatus status;
  final String? challengeNonce;
  final int? protocol;
  final ServerFeatures? features;
  final DateTime? lastConnected;
  final String? errorMessage;
  final int reconnectAttempts;
  final int? lastLatency;
  final String? serverConnId;

  const GatewayConnectionState({
    required this.status,
    this.challengeNonce,
    this.protocol,
    this.features,
    this.lastConnected,
    this.errorMessage,
    this.reconnectAttempts = 0,
    this.lastLatency,
    this.serverConnId,
  });

  factory GatewayConnectionState.initial() => const GatewayConnectionState(
    status: GatewayConnectionStatus.disconnected,
  );

  GatewayConnectionState copyWith({
    GatewayConnectionStatus? status,
    String? challengeNonce,
    int? protocol,
    ServerFeatures? features,
    DateTime? lastConnected,
    String? errorMessage,
    int? reconnectAttempts,
    int? lastLatency,
    String? serverConnId,
  }) => GatewayConnectionState(
    status: status ?? this.status,
    challengeNonce: challengeNonce ?? this.challengeNonce,
    protocol: protocol ?? this.protocol,
    features: features ?? this.features,
    lastConnected: lastConnected ?? this.lastConnected,
    errorMessage: errorMessage ?? this.errorMessage,
    reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    lastLatency: lastLatency ?? this.lastLatency,
    serverConnId: serverConnId ?? this.serverConnId,
  );

  // State helpers
  bool get isConnected => status == GatewayConnectionStatus.connected;
  bool get isConnecting => status == GatewayConnectionStatus.connecting;
  bool get isAwaitingChallenge =>
      status == GatewayConnectionStatus.awaitingChallenge;
  bool get isAuthenticating => status == GatewayConnectionStatus.authenticating;
  bool get isDisconnected => status == GatewayConnectionStatus.disconnected;
  bool get hasError => status == GatewayConnectionStatus.error;
  bool get canConnect => isDisconnected || hasError;

  // Transition helpers
  GatewayConnectionState withStatus(GatewayConnectionStatus newStatus) =>
      copyWith(status: newStatus);

  GatewayConnectionState withError(String message) =>
      copyWith(status: GatewayConnectionStatus.error, errorMessage: message);

  GatewayConnectionState withChallenge(String nonce) =>
      copyWith(challengeNonce: nonce);

  GatewayConnectionState asConnected({
    required int protocol,
    ServerFeatures? features,
    String? serverConnId,
  }) => copyWith(
    status: GatewayConnectionStatus.connected,
    protocol: protocol,
    features: features,
    serverConnId: serverConnId,
    lastConnected: DateTime.now(),
    errorMessage: null,
    reconnectAttempts: 0,
  );

  GatewayConnectionState asDisconnected() => copyWith(
    status: GatewayConnectionStatus.disconnected,
    errorMessage: null,
  );

  GatewayConnectionState asReconnecting() => copyWith(
    status: GatewayConnectionStatus.reconnecting,
    reconnectAttempts: reconnectAttempts + 1,
  );

  String get statusDisplayString {
    switch (status) {
      case GatewayConnectionStatus.disconnected:
        return 'Disconnected';
      case GatewayConnectionStatus.connecting:
        return 'Connecting...';
      case GatewayConnectionStatus.awaitingChallenge:
        return 'Awaiting challenge...';
      case GatewayConnectionStatus.authenticating:
        return 'Authenticating...';
      case GatewayConnectionStatus.connected:
        return 'Connected';
      case GatewayConnectionStatus.disconnecting:
        return 'Disconnecting...';
      case GatewayConnectionStatus.error:
        return 'Error: $errorMessage';
      case GatewayConnectionStatus.reconnecting:
        return 'Reconnecting ($reconnectAttempts)...';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GatewayConnectionState &&
          status == other.status &&
          challengeNonce == other.challengeNonce &&
          protocol == other.protocol &&
          lastConnected == other.lastConnected &&
          errorMessage == other.errorMessage &&
          reconnectAttempts == other.reconnectAttempts;

  @override
  int get hashCode => Object.hash(
    status,
    challengeNonce,
    protocol,
    lastConnected,
    errorMessage,
    reconnectAttempts,
  );
}
