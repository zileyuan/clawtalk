/// Connection status enum representing the current state of the connection
enum ConnectionStatus {
  /// Not connected to any server
  disconnected,

  /// Currently attempting to establish a connection
  connecting,

  /// Successfully connected to the server
  connected,

  /// Currently disconnecting from the server
  disconnecting,

  /// Connection encountered an error
  error,

  /// Connection lost, attempting to reconnect
  reconnecting,
}

/// Connection state model containing detailed connection information
class ConnectionState {
  final ConnectionStatus status;
  final DateTime? lastConnected;
  final String? errorMessage;
  final int reconnectAttempts;
  final int? lastLatency;
  final String? serverVersion;

  const ConnectionState({
    required this.status,
    this.lastConnected,
    this.errorMessage,
    this.reconnectAttempts = 0,
    this.lastLatency,
    this.serverVersion,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    DateTime? lastConnected,
    String? errorMessage,
    int? reconnectAttempts,
    int? lastLatency,
    String? serverVersion,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      lastConnected: lastConnected ?? this.lastConnected,
      errorMessage: errorMessage ?? this.errorMessage,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastLatency: lastLatency ?? this.lastLatency,
      serverVersion: serverVersion ?? this.serverVersion,
    );
  }

  factory ConnectionState.initial() => const ConnectionState(
    status: ConnectionStatus.disconnected,
    lastConnected: null,
    errorMessage: null,
    reconnectAttempts: 0,
    lastLatency: null,
    serverVersion: null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionState &&
          status == other.status &&
          lastConnected == other.lastConnected &&
          errorMessage == other.errorMessage &&
          reconnectAttempts == other.reconnectAttempts &&
          lastLatency == other.lastLatency &&
          serverVersion == other.serverVersion;

  @override
  int get hashCode => Object.hash(
    status,
    lastConnected,
    errorMessage,
    reconnectAttempts,
    lastLatency,
    serverVersion,
  );
}

/// Extension for ConnectionState utilities
extension ConnectionStateX on ConnectionState {
  /// Check if currently connected
  bool get isConnected => status == ConnectionStatus.connected;

  /// Check if currently connecting (includes reconnecting)
  bool get isConnecting =>
      status == ConnectionStatus.connecting ||
      status == ConnectionStatus.reconnecting;

  /// Check if currently disconnected
  bool get isDisconnected => status == ConnectionStatus.disconnected;

  /// Check if has error
  bool get hasError => status == ConnectionStatus.error;

  /// Check if can attempt to connect
  bool get canConnect => isDisconnected || hasError;

  /// Check if can disconnect
  bool get canDisconnect => isConnected || isConnecting;

  /// Get time since last connection
  Duration? get timeSinceLastConnection {
    if (lastConnected == null) return null;
    return DateTime.now().difference(lastConnected!);
  }

  /// Get status display string
  String get statusDisplayString {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.disconnecting:
        return 'Disconnecting...';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting ($reconnectAttempts)...';
    }
  }

  /// Create a copy with updated status
  ConnectionState withStatus(ConnectionStatus newStatus) =>
      copyWith(status: newStatus);

  /// Create a copy with error
  ConnectionState withError(String message) =>
      copyWith(status: ConnectionStatus.error, errorMessage: message);

  /// Create a copy for successful connection
  ConnectionState asConnected({String? serverVersion}) => copyWith(
    status: ConnectionStatus.connected,
    lastConnected: DateTime.now(),
    errorMessage: null,
    reconnectAttempts: 0,
    serverVersion: serverVersion,
  );

  /// Create a copy for reconnection attempt
  ConnectionState asReconnecting() => copyWith(
    status: ConnectionStatus.reconnecting,
    reconnectAttempts: reconnectAttempts + 1,
  );

  /// Create a copy for disconnection
  ConnectionState asDisconnected() =>
      copyWith(status: ConnectionStatus.disconnected, errorMessage: null);

  /// Update latency
  ConnectionState withLatency(int latencyMs) =>
      copyWith(lastLatency: latencyMs);
}

/// Connection state change record for tracking history
class ConnectionStateChange {
  final ConnectionState previousState;
  final ConnectionState currentState;
  final DateTime timestamp;
  final String? reason;

  ConnectionStateChange({
    required this.previousState,
    required this.currentState,
    required this.timestamp,
    this.reason,
  });

  bool get isSignificantChange => previousState.status != currentState.status;

  String get changeDescription {
    if (reason != null) return reason!;
    return '${previousState.statusDisplayString} → ${currentState.statusDisplayString}';
  }
}
