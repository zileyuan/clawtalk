import 'dart:async';

import 'package:clawtalk/acp/client/connection_config.dart';
import 'package:clawtalk/gateway/client/gateway_connection_state.dart';
import 'package:clawtalk/gateway/protocol/gateway_event.dart';
import 'package:clawtalk/gateway/protocol/gateway_request.dart';
import 'package:clawtalk/gateway/protocol/gateway_response.dart';

/// Gateway client interface for WebSocket communication
abstract class GatewayClient {
  /// Stream of connection state changes
  Stream<GatewayConnectionState> get connectionState;

  /// Current connection state
  GatewayConnectionState get currentState;

  /// Stream of incoming Gateway events
  Stream<GatewayEvent> get events;

  /// Current connection config (null if not configured)
  ConnectionConfig? get config;

  /// Whether the client is currently connected
  bool get isConnected;

  /// Whether the client is currently connecting
  /// (includes awaitingChallenge, authenticating)
  bool get isConnecting;

  /// Connect to Gateway server with given configuration
  ///
  /// This initiates the challenge-response handshake:
  /// 1. WebSocket connects
  /// 2. Server sends `connect.challenge` event
  /// 3. Client sends `connect` request with auth
  /// 4. Server responds with `hello-ok`
  ///
  /// Throws [GatewayConnectionException] if connection fails
  /// Throws [GatewayHandshakeException] if handshake fails
  Future<void> connect(ConnectionConfig config);

  /// Disconnect from server
  Future<void> disconnect({String? reason});

  /// Send a request and wait for response
  ///
  /// Returns the response
  /// Throws [GatewayTimeoutException] if request times out
  /// Throws [GatewayRequestException] if server returns error
  Future<GatewayResponse> sendRequest(GatewayRequest request);

  /// Send a notification (fire and forget)
  Future<void> sendNotification(String event, Map<String, dynamic>? payload);

  /// Send raw JSON data (for debugging)
  Future<void> sendRaw(Map<String, dynamic> data);

  /// Close the client and release all resources
  Future<void> close();
}
