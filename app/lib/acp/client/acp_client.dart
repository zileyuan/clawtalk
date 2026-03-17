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

/// ACP message types

/// Base class for ACP messages
abstract class AcpMessage {
  /// Message ID for correlation
  String get id;

  /// Message type (e.g., 'request', 'response', 'event')
  String get type;

  /// Convert to JSON
  Map<String, dynamic> toJson();
}

/// ACP request message
abstract class AcpRequest implements AcpMessage {
  @override
  String get type => 'request';

  /// Request method/action
  String get method;

  /// Request parameters
  Map<String, dynamic>? get params;
}

/// ACP response message
abstract class AcpResponse implements AcpMessage {
  @override
  String get type => 'response';

  /// Request ID this response is for
  String get requestId;

  /// Whether the request was successful
  bool get success;

  /// Response data (if successful)
  Map<String, dynamic>? get data;

  /// Error message (if failed)
  String? get error;

  /// Error code (if failed)
  String? get errorCode;
}

/// ACP notification message (fire and forget)
abstract class AcpNotification implements AcpMessage {
  @override
  String get type => 'notification';

  /// Notification event name
  String get event;

  /// Notification payload
  Map<String, dynamic>? get payload;
}

/// ACP event (incoming from server)
abstract class AcpEvent {
  /// Event name
  String get name;

  /// Event payload
  Map<String, dynamic>? get data;

  /// Event timestamp
  DateTime get timestamp;
}

/// Callback for handling incoming messages
typedef MessageHandler = void Function(AcpMessage message);

/// Callback for handling connection errors
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);

/// Callback for handling state changes
typedef StateChangeHandler =
    void Function(ConnectionState previous, ConnectionState current);
