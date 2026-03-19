import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart';

import 'package:clawtalk/gateway/client/gateway_client.dart';
import 'package:clawtalk/gateway/client/gateway_client_impl.dart';
import 'package:clawtalk/gateway/client/gateway_connection_state.dart';
import 'package:clawtalk/gateway/protocol/gateway_event.dart';
import 'package:clawtalk/features/connection/domain/entities/connection_config.dart';
import 'package:clawtalk/acp/client/connection_config.dart' as acp;
import 'package:clawtalk/core/constants/api_constants.dart';
import 'package:clawtalk/core/constants/app_constants.dart';

/// Extension to add Gateway-specific functionality to ConnectionConfig
extension ConnectionConfigGatewayX on ConnectionConfig {
  /// Build WebSocket URI from config
  Uri get wsUri {
    final scheme = useTLS ? 'wss' : 'ws';
    return Uri.parse('$scheme://$host:$port${ApiConstants.wsPath}');
  }

  /// Convert to ACP-compatible ConnectionConfig
  /// (used internally by GatewayClient)
  acp.ConnectionConfig toAcpConfig() => acp.ConnectionConfig(
    id: id,
    name: name,
    host: host,
    port: port,
    token: token,
    password: password,
    useTLS: useTLS,
    connectionTimeout: AppConstants.connectionTimeout,
    heartbeatInterval: AppConstants.heartbeatInterval,
  );
}

/// Connection manager state
class ConnectionManagerState {
  final GatewayConnectionStatus status;
  final String? activeConnectionId;
  final String? errorMessage;
  final DateTime? lastConnected;

  const ConnectionManagerState({
    this.status = GatewayConnectionStatus.disconnected,
    this.activeConnectionId,
    this.errorMessage,
    this.lastConnected,
  });

  ConnectionManagerState copyWith({
    GatewayConnectionStatus? status,
    String? activeConnectionId,
    String? errorMessage,
    DateTime? lastConnected,
  }) => ConnectionManagerState(
    status: status ?? this.status,
    activeConnectionId: activeConnectionId ?? this.activeConnectionId,
    errorMessage: errorMessage,
    lastConnected: lastConnected ?? this.lastConnected,
  );

  bool get isConnected => status == GatewayConnectionStatus.connected;
  bool get isConnecting =>
      status == GatewayConnectionStatus.connecting ||
      status == GatewayConnectionStatus.awaitingChallenge ||
      status == GatewayConnectionStatus.authenticating;
  bool get hasError => status == GatewayConnectionStatus.error;
}

/// Gateway connection manager
class ConnectionManagerNotifier extends StateNotifier<ConnectionManagerState> {
  final Logger _logger = Logger();
  GatewayClient? _client;
  StreamSubscription<GatewayConnectionState>? _stateSubscription;
  StreamSubscription<GatewayEvent>? _eventSubscription;

  final _eventController = StreamController<GatewayEvent>.broadcast();
  Stream<GatewayEvent> get events => _eventController.stream;

  ConnectionManagerNotifier() : super(const ConnectionManagerState());

  /// Connect to Gateway
  Future<void> connect(ConnectionConfig config) async {
    if (state.isConnected || state.isConnecting) {
      _logger.w('Already connected or connecting');
      return;
    }

    state = ConnectionManagerState(
      status: GatewayConnectionStatus.connecting,
      activeConnectionId: config.id,
    );

    try {
      _client = GatewayClientImpl();

      // Subscribe to state changes
      _stateSubscription = _client!.connectionState.listen(
        (gatewayState) {
          state = ConnectionManagerState(
            status: gatewayState.status,
            activeConnectionId: config.id,
            errorMessage: gatewayState.errorMessage,
            lastConnected: gatewayState.lastConnected,
          );
        },
        onError: (Object error) {
          _logger.e('Connection error: $error');
          state = ConnectionManagerState(
            status: GatewayConnectionStatus.error,
            activeConnectionId: config.id,
            errorMessage: error.toString(),
          );
        },
      );

      // Subscribe to events
      _eventSubscription = _client!.events.listen(_eventController.add);

      // Connect with challenge-response handshake
      // Convert features ConnectionConfig to ACP ConnectionConfig
      await _client!.connect(config.toAcpConfig());

      _logger.i('Connected to ${config.host}:${config.port}');
    } catch (e) {
      _logger.e('Connection error: $e');
      state = ConnectionManagerState(
        status: GatewayConnectionStatus.error,
        activeConnectionId: config.id,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Disconnect from Gateway
  Future<void> disconnect() async {
    if (state.status == GatewayConnectionStatus.disconnected) return;

    state = state.copyWith(status: GatewayConnectionStatus.disconnecting);

    try {
      await _stateSubscription?.cancel();
      _stateSubscription = null;

      await _eventSubscription?.cancel();
      _eventSubscription = null;

      await _client?.disconnect();
      _client = null;

      state = const ConnectionManagerState();
      _logger.i('Disconnected');
    } catch (e) {
      _logger.e('Disconnect error: $e');
      state = ConnectionManagerState(
        status: GatewayConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get the underlying client (throws if not connected)
  GatewayClient get client {
    if (_client == null || !_client!.isConnected) {
      throw StateError('Not connected');
    }
    return _client!;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _eventSubscription?.cancel();
    _eventController.close();
    _client?.close();
    super.dispose();
  }
}

/// Provider for connection manager
final connectionManagerProvider =
    StateNotifierProvider<ConnectionManagerNotifier, ConnectionManagerState>(
      (ref) => ConnectionManagerNotifier(),
    );

/// Provider to check if connected
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectionManagerProvider).isConnected;
});

/// Provider for active connection ID
final activeConnectionIdProvider = Provider<String?>((ref) {
  return ref.watch(connectionManagerProvider).activeConnectionId;
});

/// Provider for connection events
final connectionEventsProvider = Provider<Stream<GatewayEvent>>((ref) {
  return ref.read(connectionManagerProvider.notifier).events;
});
