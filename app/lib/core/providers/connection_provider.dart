import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/connection/domain/entities/connection_config.dart';

/// Connection status
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Connection manager state
class ConnectionManagerState {
  final ConnectionStatus status;
  final String? activeConnectionId;
  final String? errorMessage;
  final DateTime? lastConnected;

  const ConnectionManagerState({
    this.status = ConnectionStatus.disconnected,
    this.activeConnectionId,
    this.errorMessage,
    this.lastConnected,
  });

  ConnectionManagerState copyWith({
    ConnectionStatus? status,
    String? activeConnectionId,
    String? errorMessage,
    DateTime? lastConnected,
  }) {
    return ConnectionManagerState(
      status: status ?? this.status,
      activeConnectionId: activeConnectionId ?? this.activeConnectionId,
      errorMessage: errorMessage,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get hasError => status == ConnectionStatus.error;
}

/// Simple WebSocket connection manager
class ConnectionManagerNotifier extends StateNotifier<ConnectionManagerState> {
  final Logger _logger = Logger();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  ConnectionConfig? _currentConfig;

  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messages => _messageController.stream;

  ConnectionManagerNotifier() : super(const ConnectionManagerState());

  /// Connect to gateway
  Future<void> connect(ConnectionConfig config) async {
    if (state.isConnecting || state.isConnected) {
      _logger.w('Already connected or connecting');
      return;
    }

    state = ConnectionManagerState(
      status: ConnectionStatus.connecting,
      activeConnectionId: config.id,
    );

    try {
      final uri = Uri.parse('ws://${config.host}:${config.port}/ws');
      _logger.i('Connecting to $uri');

      _channel = WebSocketChannel.connect(uri, protocols: ['acp-v1']);
      _currentConfig = config;

      // Wait for connection
      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );

      // Listen for messages
      _subscription = _channel!.stream.listen(
        (data) {
          _logger.d('Received: $data');
          _messageController.add(data.toString());
        },
        onError: (error) {
          _logger.e('WebSocket error: $error');
          state = ConnectionManagerState(
            status: ConnectionStatus.error,
            activeConnectionId: config.id,
            errorMessage: error.toString(),
          );
        },
        onDone: () {
          _logger.i('WebSocket closed');
          state = ConnectionManagerState(
            status: ConnectionStatus.disconnected,
            activeConnectionId: config.id,
          );
        },
      );

      state = state.copyWith(
        status: ConnectionStatus.connected,
        lastConnected: DateTime.now(),
      );

      _logger.i('Connected to ${config.host}:${config.port}');
    } on TimeoutException catch (e) {
      _logger.e('Connection timeout: $e');
      state = ConnectionManagerState(
        status: ConnectionStatus.error,
        activeConnectionId: config.id,
        errorMessage: 'Connection timeout',
      );
      rethrow;
    } catch (e) {
      _logger.e('Connection error: $e');
      state = ConnectionManagerState(
        status: ConnectionStatus.error,
        activeConnectionId: config.id,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Disconnect from gateway
  Future<void> disconnect() async {
    if (state.status == ConnectionStatus.disconnected) return;

    state = state.copyWith(status: ConnectionStatus.disconnecting);

    try {
      await _subscription?.cancel();
      _subscription = null;

      await _channel?.sink.close();
      _channel = null;
      _currentConfig = null;

      state = const ConnectionManagerState();
      _logger.i('Disconnected');
    } catch (e) {
      _logger.e('Disconnect error: $e');
      state = ConnectionManagerState(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Send a message
  void send(String message) {
    if (_channel == null) {
      throw StateError('Not connected');
    }
    _channel!.sink.add(message);
    _logger.d('Sent: $message');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.close();
    _channel?.sink.close();
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

/// Provider for connection messages
final connectionMessagesProvider = Provider<Stream<String>>((ref) {
  return ref.read(connectionManagerProvider.notifier).messages;
});
