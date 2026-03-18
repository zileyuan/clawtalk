import 'dart:async';

import 'connection_config.dart';
import 'connection_state.dart';
import '../protocol/acp_message.dart';

/// Abstract interface for ACP client
///
/// This interface defines the contract for ACP WebSocket clients.
/// Implementations should handle:
/// - Connection lifecycle (connect, disconnect, reconnect)
/// - Message sending and receiving
/// - State management via streams
abstract class AcpClient {
  /// Stream of connection state changes
  Stream<ConnectionState> get connectionState;

  /// Current connection state
  ConnectionState get currentState;

  /// Stream of incoming ACP events
  Stream<AcpEvent> get events;

  /// Current connection config (null if not configured)
  ConnectionConfig? get config;

  /// Whether the client is currently connected
  bool get isConnected;

  /// Whether the client is currently connecting
  bool get isConnecting;

  /// Connect to server with given configuration
  ///
  /// Throws [AcpConnectionException] if connection fails
  Future<void> connect(ConnectionConfig config);

  /// Disconnect from server
  ///
  /// If [reason] is provided, it will be sent to the server
  Future<void> disconnect({String? reason});

  /// Send a request and wait for response
  ///
  /// Returns the response of type [T]
  /// Throws [AcpTimeoutException] if request times out
  /// Throws [AcpProtocolException] if server returns error
  Future<T> sendRequest<T extends AcpResponse>(AcpRequest request);

  /// Send a request without waiting for response (fire and forget)
  ///
  /// Returns a Future that completes when the message is sent
  Future<void> sendNotification(AcpNotification notification);

  /// Send raw JSON data
  ///
  /// Use this for debugging or when message types are not known
  Future<void> sendRaw(Map<String, dynamic> data);

  /// Close the client and release all resources
  Future<void> close();
}

/// Callback for handling incoming messages
typedef MessageHandler = void Function(AcpMessageBase message);

/// Callback for handling connection errors
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);

/// Callback for handling state changes
typedef StateChangeHandler =
    void Function(ConnectionState previous, ConnectionState current);
