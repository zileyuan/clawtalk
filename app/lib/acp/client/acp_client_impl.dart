import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'acp_client.dart';
import 'connection_config.dart';
import 'connection_state.dart';
import 'message_queue.dart';
import '../exceptions/acp_exception.dart';
import '../protocol/acp_message.dart';

/// WebSocket implementation of ACP client
class AcpClientImpl implements AcpClient {
  final Logger _logger;
  final MessageQueue<Map<String, dynamic>> _messageQueue;

  WebSocketChannel? _channel;
  ConnectionConfig? _config;
  ConnectionState _state = ConnectionState.initial();

  final _stateController = StreamController<ConnectionState>.broadcast();
  final _eventController = StreamController<AcpEvent>.broadcast();
  final _responseCompleters = <String, Completer<AcpResponse>>{};

  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  /// Create a new ACP client
  AcpClientImpl({
    Logger? logger,
    MessageQueue<Map<String, dynamic>>? messageQueue,
  }) : _logger = logger ?? Logger(printer: PrettyPrinter()),
       _messageQueue = messageQueue ?? MessageQueue<Map<String, dynamic>>();

  @override
  Stream<ConnectionState> get connectionState => _stateController.stream;

  @override
  ConnectionState get currentState => _state;

  @override
  Stream<AcpEvent> get events => _eventController.stream;

  @override
  ConnectionConfig? get config => _config;

  @override
  bool get isConnected => _state.isConnected;

  @override
  bool get isConnecting => _state.isConnecting;

  @override
  Future<void> connect(ConnectionConfig config) async {
    if (_state.isConnected || _state.isConnecting) {
      throw AcpStateException.alreadyConnected();
    }

    _config = config;
    _updateState(_state.withStatus(ConnectionStatus.connecting));

    try {
      _logger.i('Connecting to ${config.wsUri}');
      final uri = config.wsUri;

      _channel = WebSocketChannel.connect(uri, protocols: ['acp-v1']);

      // Wait for connection
      await _channel!.ready.timeout(
        config.connectionTimeout,
        onTimeout: () => throw AcpConnectionException.timeout(
          'Connection timeout after ${config.connectionTimeout.inSeconds}s',
        ),
      );

      // Set up message listener
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _updateState(_state.asConnected());
      _logger.i('Connected to ${config.wsUri}');

      // Start heartbeat
      _startHeartbeat();
    } on AcpException {
      rethrow;
    } catch (e) {
      _logger.e('Connection failed: $e');
      _updateState(_state.withError(e.toString()));
      throw AcpConnectionException('Failed to connect: $e', originalError: e);
    }
  }

  @override
  Future<void> disconnect({String? reason}) async {
    if (_state.isDisconnected) return;

    _updateState(_state.withStatus(ConnectionStatus.disconnecting));

    try {
      _stopHeartbeat();
      _stopReconnect();

      // Close all pending requests
      for (final completer in _responseCompleters.values) {
        if (!completer.isCompleted) {
          completer.completeError(AcpStateException.notConnected());
        }
      }
      _responseCompleters.clear();

      // Close WebSocket
      await _subscription?.cancel();
      _subscription = null;

      await _channel?.close(
        ws_status.goingAway,
        reason ?? 'Client disconnecting',
      );
      _channel = null;

      _updateState(_state.asDisconnected());
      _logger.i('Disconnected');
    } catch (e) {
      _logger.e('Disconnect error: $e');
      _updateState(_state.withError(e.toString()));
    }
  }

  @override
  Future<T> sendRequest<T extends AcpResponse>(AcpRequest request) async {
    if (!_state.isConnected) {
      throw AcpStateException.notConnected();
    }

    final completer = Completer<AcpResponse>();
    _responseCompleters[request.id] = completer;

    try {
      final json = AcpMessageSerializer.serializeRequest(request);
      _sendMessage(json);

      // Wait for response with timeout
      final response = await completer.future.timeout(
        _config?.connectionTimeout ?? const Duration(seconds: 30),
        onTimeout: () => throw AcpTimeoutException.requestTimeout(
          request.id,
          _config?.connectionTimeout ?? const Duration(seconds: 30),
        ),
      );

      if (!response.success) {
        throw AcpRequestException(
          response.error ?? 'Request failed',
          code: response.errorCode,
          requestId: request.id,
        );
      }

      return response as T;
    } finally {
      _responseCompleters.remove(request.id);
    }
  }

  @override
  Future<void> sendNotification(AcpNotification notification) async {
    if (!_state.isConnected) {
      throw AcpStateException.notConnected();
    }

    final json = AcpMessageSerializer.serializeNotification(notification);
    _sendMessage(json);
  }

  @override
  Future<void> sendRaw(Map<String, dynamic> data) async {
    if (!_state.isConnected) {
      throw AcpStateException.notConnected();
    }

    _sendMessage(data);
  }

  @override
  Future<void> close() async {
    await disconnect();
    await _stateController.close();
    await _eventController.close();
    _messageQueue.dispose();
  }

  /// Send a message through the WebSocket
  void _sendMessage(Map<String, dynamic> data) {
    if (_channel == null) return;

    final jsonStr = jsonEncode(data);
    _logger.d('Sending: $jsonStr');
    _channel!.sink.add(jsonStr);
  }

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      _logger.d('Received: $json');

      final message = AcpMessageSerializer.deserialize(json);

      if (message == null) {
        _logger.w('Failed to deserialize message: $json');
        return;
      }

      switch (message) {
        case AcpResponse response:
          _handleResponse(response);
        case AcpEvent event:
          _eventController.add(event);
        case AcpPong pong:
          _handlePong(pong);
        default:
          _logger.w('Unhandled message type: ${message.runtimeType}');
      }
    } catch (e, st) {
      _logger.e('Error handling message: $e', error: e, stackTrace: st);
    }
  }

  /// Handle response message
  void _handleResponse(AcpResponse response) {
    final completer = _responseCompleters[response.requestId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
    }
  }

  /// Handle pong message
  void _handlePong(AcpPong pong) {
    // Update latency if we have the ping timestamp
    // This is a simple latency calculation
    final latency = DateTime.now().difference(pong.timestamp);
    _updateState(_state.withLatency(latency.inMilliseconds));
  }

  /// Handle WebSocket error
  void _handleError(dynamic error) {
    _logger.e('WebSocket error: $error');
    _updateState(_state.withError(error.toString()));
  }

  /// Handle WebSocket close
  void _handleDone() {
    _logger.i('WebSocket closed');

    if (_state.isConnected) {
      // Unexpected disconnect, attempt reconnect
      _updateState(_state.withError('Connection lost'));
      _scheduleReconnect();
    }
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _stopHeartbeat();

    final interval = _config?.heartbeatInterval ?? const Duration(seconds: 30);
    _heartbeatTimer = Timer.periodic(interval, (_) {
      if (_state.isConnected) {
        _sendPing();
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send ping message
  void _sendPing() {
    final ping = AcpPing.create();
    final json = AcpMessageSerializer.serializePing(ping);
    _sendMessage(json);
  }

  /// Schedule reconnect attempt
  void _scheduleReconnect() {
    _stopReconnect();

    if (_config == null) return;

    final delay = Duration(seconds: 1 << _state.reconnectAttempts.clamp(0, 5));

    _logger.i('Scheduling reconnect in ${delay.inSeconds}s');
    _updateState(_state.asReconnecting());

    _reconnectTimer = Timer(delay, () {
      if (_config != null) {
        connect(_config!);
      }
    });
  }

  /// Stop reconnect timer
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Update connection state and notify listeners
  void _updateState(ConnectionState newState) {
    final oldState = _state;
    _state = newState;
    _stateController.add(newState);
    _logger.d('State: ${oldState.status} -> ${newState.status}');
  }
}
