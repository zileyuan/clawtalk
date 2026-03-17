/// Enum representing the possible states of a connection.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Information about the current status of a connection.
class ConnectionStatusInfo {
  final String connectionId;
  final ConnectionStatus status;
  final DateTime? lastConnected;
  final String? errorMessage;

  const ConnectionStatusInfo({
    required this.connectionId,
    required this.status,
    this.lastConnected,
    this.errorMessage,
  });

  ConnectionStatusInfo copyWith({
    String? connectionId,
    ConnectionStatus? status,
    DateTime? lastConnected,
    String? errorMessage,
  }) {
    return ConnectionStatusInfo(
      connectionId: connectionId ?? this.connectionId,
      status: status ?? this.status,
      lastConnected: lastConnected ?? this.lastConnected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionStatusInfo &&
        other.connectionId == connectionId &&
        other.status == status &&
        other.lastConnected == lastConnected &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(connectionId, status, lastConnected, errorMessage);
  }

  @override
  String toString() {
    return 'ConnectionStatusInfo(connectionId: $connectionId, status: $status, '
        'lastConnected: $lastConnected, errorMessage: $errorMessage)';
  }
}
