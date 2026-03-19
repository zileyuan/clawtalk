import 'dart:async';
import 'dart:convert';

import 'package:clawtalk/acp/client/connection_config.dart';
import 'package:clawtalk/gateway/client/gateway_client.dart';
import 'package:clawtalk/gateway/client/gateway_connection_state.dart';
import 'package:clawtalk/gateway/constants/gateway_constants.dart';
import 'package:clawtalk/gateway/crypto/device_identity.dart';
import 'package:clawtalk/gateway/exceptions/gateway_exception.dart';
import 'package:clawtalk/gateway/protocol/gateway_event.dart';
import 'package:clawtalk/gateway/protocol/gateway_request.dart';
import 'package:clawtalk/gateway/protocol/gateway_response.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket implementation of Gateway client
class GatewayClientImpl implements GatewayClient {
  final Logger _logger;

  WebSocketChannel? _channel;
  ConnectionConfig? _config;
  GatewayConnectionState _state = GatewayConnectionState.initial();

  final _stateController = StreamController<GatewayConnectionState>.broadcast();
  final _eventController = StreamController<GatewayEvent>.broadcast();
  final _responseCompleters = <String, Completer<GatewayResponse>>{};

  StreamSubscription<dynamic>? _subscription;
  Timer? _handshakeTimer;
  Timer? _tickTimer;
  Completer<void>? _challengeCompleter;
  Completer<void>? _helloCompleter;
  HelloOkPayload? _helloOkPayload;

  /// Create a new Gateway client
  GatewayClientImpl({Logger? logger})
    : _logger =
          logger ??
          Logger(printer: PrettyPrinter(methodCount: 0), level: Level.debug);

  @override
  Stream<GatewayConnectionState> get connectionState => _stateController.stream;

  @override
  GatewayConnectionState get currentState => _state;

  @override
  Stream<GatewayEvent> get events => _eventController.stream;

  @override
  ConnectionConfig? get config => _config;

  @override
  bool get isConnected => _state.isConnected;

  @override
  bool get isConnecting =>
      _state.isConnecting ||
      _state.isAwaitingChallenge ||
      _state.isAuthenticating;

  @override
  Future<void> connect(ConnectionConfig config) async {
    if (_state.isConnected || isConnecting) {
      throw GatewayStateException.alreadyConnected();
    }

    _config = config;
    _updateState(_state.withStatus(GatewayConnectionStatus.connecting));

    try {
      _logger.i('Connecting to ${config.wsUri}');

      // Connect WITHOUT subprotocol (key difference from ACP)
      _channel = WebSocketChannel.connect(config.wsUri);

      await _channel!.ready.timeout(
        config.connectionTimeout,
        onTimeout: () => throw GatewayConnectionException.timeout(),
      );

      _updateState(
        _state.withStatus(GatewayConnectionStatus.awaitingChallenge),
      );

      // Set up message listener BEFORE waiting for challenge
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // Start handshake timeout
      _startHandshakeTimeout();

      // Wait for challenge event
      await _waitForChallenge();

      // Send connect request
      await _sendConnectRequest();

      // Wait for hello-ok
      await _waitForHelloOk();

      // Connection complete
      _stopHandshakeTimeout();
      _updateState(
        _state.asConnected(
          protocol: _helloOkPayload?.protocol ?? 3,
          features: _helloOkPayload?.features,
        ),
      );

      _logger.i('Connected to Gateway (protocol ${_state.protocol})');

      // Start tick timer
      _startTick();
    } catch (e) {
      _stopHandshakeTimeout();
      _updateState(_state.withError(e.toString()));
      await _cleanup();
      rethrow;
    }
  }

  Future<void> _waitForChallenge() async {
    _logger.i('[GATEWAY] Waiting for connect.challenge event...');
    _challengeCompleter = Completer<void>();
    await _challengeCompleter!.future;
    _logger.i('[GATEWAY] Challenge received, nonce: ${_state.challengeNonce}');
  }

  Future<void> _sendConnectRequest() async {
    _updateState(_state.withStatus(GatewayConnectionStatus.authenticating));
    _logger.i('[GATEWAY] Sending connect request...');

    // Load or create device identity
    final deviceService = DeviceIdentityService();
    final identity = await deviceService.loadOrCreate();

    // Build device signature
    final signature = deviceService.buildSignaturePayload(
      identity: identity,
      nonce: _state.challengeNonce!,
    );

    _logger.i(
      '[GATEWAY] Device signature created: deviceId=${identity.deviceId}',
    );

    final request = GatewayRequestFactory.connect(
      nonce: _state.challengeNonce!,
      token: _config!.token,
      password: _config!.password,
      deviceSignature: signature,
    );

    _logger.i('[GATEWAY] Connect request: ${request.toJson()}');
    _sendMessage(request.toJson());
  }

  Future<void> _waitForHelloOk() async {
    _logger.i('[GATEWAY] Waiting for hello-ok response...');
    _helloCompleter = Completer<void>();
    await _helloCompleter!.future;
    _logger.i(
      '[GATEWAY] hello-ok received, protocol: ${_helloOkPayload?.protocol}',
    );
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      _logger.d('Received: $json');

      switch (type) {
        case 'res':
          _handleResponse(GatewayResponse.fromJson(json));
        case 'event':
          _handleEvent(GatewayEvent.fromJson(json));
        default:
          _logger.w('Unknown message type: $type');
      }
    } catch (e, st) {
      _logger.e('Error handling message', error: e, stackTrace: st);
    }
  }

  void _handleResponse(GatewayResponse response) {
    // Check if this is the hello-ok response for handshake
    if (_helloCompleter != null && !_helloCompleter!.isCompleted) {
      if (response.ok && response.payload != null) {
        final payload = response.payload!;
        if (payload['type'] == 'hello-ok') {
          _helloOkPayload = HelloOkPayload.fromJson(payload);
          _helloCompleter!.complete();
          return;
        }
      } else if (!response.ok) {
        _helloCompleter!.completeError(
          GatewayHandshakeException.authFailed(
            response.error?.message ?? 'Unknown error',
          ),
        );
        return;
      }
    }

    // Regular request/response matching
    final completer = _responseCompleters[response.id];
    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
      _responseCompleters.remove(response.id);
    }
  }

  void _handleEvent(GatewayEvent event) {
    _logger.i('[GATEWAY] Event received: ${event.event}');

    // Handle challenge event during handshake
    if (event.isType(GatewayEventType.connectChallenge)) {
      final challenge = ChallengePayload.fromJson(event.payload!);
      _logger.i('[GATEWAY] Challenge event: nonce=${challenge.nonce}');
      _updateState(_state.withChallenge(challenge.nonce));
      _challengeCompleter?.complete();
      return;
    }

    // Handle tick event
    if (event.isType(GatewayEventType.tick)) {
      _logger.d('[GATEWAY] Tick received');
      return;
    }

    // Emit event to stream
    _eventController.add(event);
  }

  void _handleError(dynamic error) {
    _logger.e('WebSocket error: $error');
    _updateState(_state.withError(error.toString()));
  }

  void _handleDone() {
    _logger.i('WebSocket closed');

    if (_state.isConnected) {
      _updateState(_state.withError('Connection lost'));
      _scheduleReconnect();
    }
  }

  void _startHandshakeTimeout() {
    _handshakeTimer = Timer(GatewayConstants.handshakeTimeout, () {
      if (_state.isAwaitingChallenge) {
        _challengeCompleter?.completeError(
          GatewayHandshakeException.noChallenge(),
        );
      } else if (_state.isAuthenticating) {
        _helloCompleter?.completeError(GatewayHandshakeException.noHello());
      }
    });
  }

  void _stopHandshakeTimeout() {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(GatewayConstants.tickInterval, (_) {
      // Tick is handled by server, just check connection
    });
  }

  void _scheduleReconnect() {
    // TODO(zileyuan): Implement reconnection logic
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel == null) return;

    final jsonStr = jsonEncode(data);
    _logger.d('Sending: $jsonStr');
    _channel!.sink.add(jsonStr);
  }

  @override
  Future<GatewayResponse> sendRequest(GatewayRequest request) async {
    if (!_state.isConnected) {
      throw GatewayStateException.notConnected();
    }

    final completer = Completer<GatewayResponse>();
    _responseCompleters[request.id] = completer;

    try {
      _sendMessage(request.toJson());

      final response = await completer.future.timeout(
        _config?.connectionTimeout ?? GatewayConstants.handshakeTimeout,
        onTimeout: () => throw GatewayTimeoutException.request(
          request.id,
          _config?.connectionTimeout ?? GatewayConstants.handshakeTimeout,
        ),
      );

      if (!response.ok) {
        throw GatewayRequestException(
          response.error?.message ?? 'Request failed',
          code: response.error?.code,
          requestId: request.id,
        );
      }

      return response;
    } finally {
      _responseCompleters.remove(request.id);
    }
  }

  @override
  Future<void> sendNotification(
    String event,
    Map<String, dynamic>? payload,
  ) async {
    if (!_state.isConnected) {
      throw GatewayStateException.notConnected();
    }

    _sendMessage({
      'type': 'notification',
      'event': event,
      if (payload != null) 'payload': payload,
    });
  }

  @override
  Future<void> sendRaw(Map<String, dynamic> data) async {
    if (!_state.isConnected) {
      throw GatewayStateException.notConnected();
    }

    _sendMessage(data);
  }

  @override
  Future<void> disconnect({String? reason}) async {
    if (_state.isDisconnected) return;

    _updateState(_state.withStatus(GatewayConnectionStatus.disconnecting));

    await _cleanup(reason: reason);

    _updateState(_state.asDisconnected());
    _logger.i('Disconnected');
  }

  @override
  Future<void> close() async {
    await disconnect();
    await _stateController.close();
    await _eventController.close();
  }

  Future<void> _cleanup({String? reason}) async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _stopHandshakeTimeout();

    for (final completer in _responseCompleters.values) {
      if (!completer.isCompleted) {
        completer.completeError(GatewayStateException.notConnected());
      }
    }
    _responseCompleters.clear();

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close(
      ws_status.goingAway,
      reason ?? 'Client disconnecting',
    );
    _channel = null;
  }

  void _updateState(GatewayConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }
}
