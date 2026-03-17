import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/connection_status.dart';

/// State for connection status
class ConnectionStatusState {
  final Map<String, ConnectionStatusInfo> statuses;
  final bool isMonitoring;

  const ConnectionStatusState({
    this.statuses = const {},
    this.isMonitoring = false,
  });

  ConnectionStatusState copyWith({
    Map<String, ConnectionStatusInfo>? statuses,
    bool? isMonitoring,
  }) {
    return ConnectionStatusState(
      statuses: statuses ?? this.statuses,
      isMonitoring: isMonitoring ?? this.isMonitoring,
    );
  }

  /// Get status for specific connection
  ConnectionStatusInfo? getStatus(String connectionId) {
    return statuses[connectionId];
  }

  /// Check if connection is connected
  bool isConnected(String connectionId) {
    return statuses[connectionId]?.status == ConnectionStatus.connected;
  }

  /// Check if connection is connecting
  bool isConnecting(String connectionId) {
    return statuses[connectionId]?.status == ConnectionStatus.connecting;
  }

  /// Check if any connection has error
  bool hasError(String connectionId) {
    return statuses[connectionId]?.status == ConnectionStatus.error;
  }
}

/// Notifier for managing real-time connection status
class ConnectionStatusNotifier extends StateNotifier<ConnectionStatusState> {
  Timer? _pollingTimer;

  ConnectionStatusNotifier() : super(const ConnectionStatusState());

  /// Start monitoring connection statuses
  void startMonitoring() {
    if (state.isMonitoring) return;

    state = state.copyWith(isMonitoring: true);

    // Poll for status updates every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollStatuses();
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(isMonitoring: false);
  }

  /// Poll current statuses (simulated for now)
  void _pollStatuses() {
    // TODO: Replace with actual status polling from connection manager
    // For now, keep existing statuses
  }

  /// Update status for a specific connection
  void updateStatus(ConnectionStatusInfo statusInfo) {
    final updatedStatuses = Map<String, ConnectionStatusInfo>.from(
      state.statuses,
    );
    updatedStatuses[statusInfo.connectionId] = statusInfo;
    state = state.copyWith(statuses: updatedStatuses);
  }

  /// Set connection to connecting state
  void setConnecting(String connectionId) {
    _updateStatus(connectionId, ConnectionStatus.connecting);
  }

  /// Set connection to connected state
  void setConnected(String connectionId) {
    _updateStatus(
      connectionId,
      ConnectionStatus.connected,
      lastConnected: DateTime.now(),
    );
  }

  /// Set connection to disconnected state
  void setDisconnected(String connectionId) {
    _updateStatus(connectionId, ConnectionStatus.disconnected);
  }

  /// Set connection to disconnecting state
  void setDisconnecting(String connectionId) {
    _updateStatus(connectionId, ConnectionStatus.disconnecting);
  }

  /// Set connection to error state
  void setError(String connectionId, String errorMessage) {
    _updateStatus(
      connectionId,
      ConnectionStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Helper to update status
  void _updateStatus(
    String connectionId,
    ConnectionStatus status, {
    DateTime? lastConnected,
    String? errorMessage,
  }) {
    final updatedStatuses = Map<String, ConnectionStatusInfo>.from(
      state.statuses,
    );
    updatedStatuses[connectionId] = ConnectionStatusInfo(
      connectionId: connectionId,
      status: status,
      lastConnected:
          lastConnected ?? updatedStatuses[connectionId]?.lastConnected,
      errorMessage: errorMessage,
    );
    state = state.copyWith(statuses: updatedStatuses);
  }

  /// Remove status for a connection (when deleted)
  void removeStatus(String connectionId) {
    final updatedStatuses = Map<String, ConnectionStatusInfo>.from(
      state.statuses,
    );
    updatedStatuses.remove(connectionId);
    state = state.copyWith(statuses: updatedStatuses);
  }

  /// Connect to a connection
  Future<void> connect(String connectionId) async {
    setConnecting(connectionId);

    try {
      // TODO: Replace with actual connection logic
      await Future.delayed(const Duration(seconds: 1));
      setConnected(connectionId);
    } catch (e) {
      setError(connectionId, e.toString());
    }
  }

  /// Disconnect from a connection
  Future<void> disconnect(String connectionId) async {
    setDisconnecting(connectionId);

    try {
      // TODO: Replace with actual disconnection logic
      await Future.delayed(const Duration(milliseconds: 500));
      setDisconnected(connectionId);
    } catch (e) {
      setError(connectionId, e.toString());
    }
  }

  /// Reconnect to a connection
  Future<void> reconnect(String connectionId) async {
    await disconnect(connectionId);
    await Future.delayed(const Duration(milliseconds: 300));
    await connect(connectionId);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Provider for connection status state
final connectionStatusProvider =
    StateNotifierProvider<ConnectionStatusNotifier, ConnectionStatusState>(
      (ref) => ConnectionStatusNotifier(),
    );

/// Provider for specific connection status
final connectionStatusByIdProvider =
    Provider.family<ConnectionStatusInfo?, String>((ref, connectionId) {
      final state = ref.watch(connectionStatusProvider);
      return state.getStatus(connectionId);
    });

/// Provider to check if a connection is connected
final isConnectedProvider = Provider.family<bool, String>((ref, connectionId) {
  final state = ref.watch(connectionStatusProvider);
  return state.isConnected(connectionId);
});

/// Provider to check if a connection is in progress (connecting/disconnecting)
final isConnectionInProgressProvider = Provider.family<bool, String>((
  ref,
  connectionId,
) {
  final status = ref.watch(connectionStatusByIdProvider(connectionId));
  return status?.status == ConnectionStatus.connecting ||
      status?.status == ConnectionStatus.disconnecting;
});
