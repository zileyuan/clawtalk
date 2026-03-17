import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/providers/connection_provider.dart' as manager;
import '../../domain/entities/connection_config.dart';
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
  final Ref _ref;
  Timer? _pollingTimer;

  ConnectionStatusNotifier(this._ref) : super(const ConnectionStatusState());

  /// Start monitoring connection statuses
  void startMonitoring() {
    if (state.isMonitoring) return;

    state = state.copyWith(isMonitoring: true);

    // Sync with connection manager state
    _syncWithConnectionManager();

    // Poll for status updates every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _syncWithConnectionManager();
    });
  }

  /// Sync with connection manager
  void _syncWithConnectionManager() {
    final managerState = _ref.read(manager.connectionManagerProvider);
    final activeId = managerState.activeConnectionId;

    if (activeId != null) {
      final status = _mapConnectionStatus(managerState.status);
      _updateStatus(
        activeId,
        status,
        errorMessage: managerState.errorMessage,
        lastConnected: managerState.lastConnected,
      );
    }
  }

  /// Map connection manager status to local status
  ConnectionStatus _mapConnectionStatus(manager.ConnectionStatus status) {
    switch (status) {
      case manager.ConnectionStatus.connected:
        return ConnectionStatus.connected;
      case manager.ConnectionStatus.connecting:
        return ConnectionStatus.connecting;
      case manager.ConnectionStatus.disconnecting:
        return ConnectionStatus.disconnecting;
      case manager.ConnectionStatus.disconnected:
        return ConnectionStatus.disconnected;
      case manager.ConnectionStatus.error:
        return ConnectionStatus.error;
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(isMonitoring: false);
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

  /// Connect to a connection using real ACP client
  Future<void> connectToConnection(ConnectionConfig config) async {
    setConnecting(config.id);

    try {
      await _ref
          .read(manager.connectionManagerProvider.notifier)
          .connect(config);
      setConnected(config.id);
    } catch (e) {
      setError(config.id, e.toString());
      rethrow;
    }
  }

  /// Connect to a connection (legacy method for compatibility)
  Future<void> connect(String connectionId) async {
    setConnecting(connectionId);

    try {
      // This is a legacy method - the actual connection should use connectToConnection
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
      await _ref.read(manager.connectionManagerProvider.notifier).disconnect();
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
      (ref) => ConnectionStatusNotifier(ref),
    );

/// Provider for specific connection status
final connectionStatusByIdProvider =
    Provider.family<ConnectionStatusInfo?, String>((ref, connectionId) {
      final state = ref.watch(connectionStatusProvider);
      return state.getStatus(connectionId);
    });

/// Provider to check if a connection is connected
final isConnectedByIdProvider = Provider.family<bool, String>((
  ref,
  connectionId,
) {
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
