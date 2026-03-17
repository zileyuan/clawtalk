import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../client/acp_client.dart';
import '../client/connection_state.dart';
import '../exceptions/acp_exception.dart';
import '../protocol/acp_message.dart';

/// Heartbeat service provider
final heartbeatServiceProvider = Provider<HeartbeatService>((ref) {
  return HeartbeatService();
});

/// Service for managing connection keepalive via heartbeat
class HeartbeatService {
  final Logger _logger;

  Timer? _heartbeatTimer;
  Timer? _timeoutTimer;

  AcpClient? _client;
  Duration _interval;
  Duration _timeout;

  DateTime? _lastPingSent;
  DateTime? _lastPongReceived;

  final _latencyController = StreamController<int>.broadcast();
  final _healthController = StreamController<ConnectionHealth>.broadcast();

  HeartbeatService({Logger? logger, Duration? interval, Duration? timeout})
    : _logger = logger ?? Logger(),
      _interval = interval ?? const Duration(seconds: 30),
      _timeout = timeout ?? const Duration(seconds: 10);

  /// Stream of latency measurements (in milliseconds)
  Stream<int> get latencyStream => _latencyController.stream;

  /// Stream of connection health updates
  Stream<ConnectionHealth> get healthStream => _healthController.stream;

  /// Current heartbeat interval
  Duration get interval => _interval;

  /// Current heartbeat timeout
  Duration get timeout => _timeout;

  /// Last measured latency (null if no measurement yet)
  int? get currentLatency => _lastPongReceived != null && _lastPingSent != null
      ? _lastPongReceived!.difference(_lastPingSent!).inMilliseconds
      : null;

  /// Whether heartbeat is active
  bool get isActive => _heartbeatTimer != null;

  /// Initialize heartbeat service with an ACP client
  void initialize(AcpClient client, {Duration? interval, Duration? timeout}) {
    stop();

    _client = client;
    if (interval != null) _interval = interval;
    if (timeout != null) _timeout = timeout;

    // Start heartbeat
    start();
  }

  /// Start heartbeat monitoring
  void start() {
    if (_client == null) {
      throw StateError('Client not initialized');
    }

    stop();

    _logger.i('Starting heartbeat with interval ${_interval.inSeconds}s');

    // Send first ping immediately
    _sendPing();

    // Schedule periodic heartbeats
    _heartbeatTimer = Timer.periodic(_interval, (_) {
      _sendPing();
    });

    // Listen for connection state changes
    _client!.connectionState.listen(_handleConnectionState);
  }

  /// Stop heartbeat monitoring
  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _lastPingSent = null;
    _lastPongReceived = null;
  }

  /// Send a ping and wait for pong
  void _sendPing() {
    if (_client == null || !_client!.isConnected) {
      _logger.w('Cannot send ping: client not connected');
      return;
    }

    _lastPingSent = DateTime.now();

    try {
      final ping = AcpPing.create();
      _client!.sendRaw(AcpMessageSerializer.serializePing(ping));

      _logger.d('Ping sent at $_lastPingSent');

      // Start timeout timer
      _startTimeoutTimer();
    } catch (e) {
      _logger.e('Failed to send ping: $e');
      _notifyHealth(ConnectionHealth.heartbeatFailed);
    }
  }

  /// Start timeout timer for pong response
  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(_timeout, () {
      _logger.w('Heartbeat timeout - no pong received');
      _notifyHealth(ConnectionHealth.heartbeatTimeout);
    });
  }

  /// Handle pong response
  void handlePong(AcpPong pong) {
    _lastPongReceived = DateTime.now();
    _timeoutTimer?.cancel();

    final latency = currentLatency;
    if (latency != null) {
      _logger.d('Pong received, latency: ${latency}ms');
      _latencyController.add(latency);
    }

    // Determine health based on latency
    if (latency != null) {
      if (latency < 100) {
        _notifyHealth(ConnectionHealth.excellent);
      } else if (latency < 300) {
        _notifyHealth(ConnectionHealth.good);
      } else if (latency < 1000) {
        _notifyHealth(ConnectionHealth.fair);
      } else {
        _notifyHealth(ConnectionHealth.poor);
      }
    }
  }

  /// Handle connection state changes
  void _handleConnectionState(ConnectionState state) {
    if (state.isDisconnected || state.hasError) {
      _logger.i('Connection lost, stopping heartbeat');
      stop();
    }
  }

  /// Notify health status
  void _notifyHealth(ConnectionHealth health) {
    _healthController.add(health);
  }

  /// Dispose resources
  void dispose() {
    stop();
    _latencyController.close();
    _healthController.close();
  }
}

/// Connection health status
enum ConnectionHealth {
  /// Excellent connection (< 100ms latency)
  excellent,

  /// Good connection (100-300ms latency)
  good,

  /// Fair connection (300-1000ms latency)
  fair,

  /// Poor connection (> 1000ms latency)
  poor,

  /// Heartbeat failed to send
  heartbeatFailed,

  /// No response to heartbeat (timeout)
  heartbeatTimeout,

  /// Connection lost
  disconnected,
}

/// Extension for ConnectionHealth
extension ConnectionHealthX on ConnectionHealth {
  /// Whether the connection is healthy
  bool get isHealthy =>
      this == ConnectionHealth.excellent ||
      this == ConnectionHealth.good ||
      this == ConnectionHealth.fair;

  /// Whether connection needs attention
  bool get needsAttention =>
      this == ConnectionHealth.poor ||
      this == ConnectionHealth.heartbeatFailed ||
      this == ConnectionHealth.heartbeatTimeout;

  /// Get display string
  String get displayString {
    switch (this) {
      case ConnectionHealth.excellent:
        return 'Excellent';
      case ConnectionHealth.good:
        return 'Good';
      case ConnectionHealth.fair:
        return 'Fair';
      case ConnectionHealth.poor:
        return 'Poor';
      case ConnectionHealth.heartbeatFailed:
        return 'Heartbeat Failed';
      case ConnectionHealth.heartbeatTimeout:
        return 'Connection Timeout';
      case ConnectionHealth.disconnected:
        return 'Disconnected';
    }
  }

  /// Get description
  String get description {
    switch (this) {
      case ConnectionHealth.excellent:
        return 'Connection is excellent with very low latency';
      case ConnectionHealth.good:
        return 'Connection is good with acceptable latency';
      case ConnectionHealth.fair:
        return 'Connection is fair with moderate latency';
      case ConnectionHealth.poor:
        return 'Connection is poor with high latency';
      case ConnectionHealth.heartbeatFailed:
        return 'Failed to send heartbeat, connection may be unstable';
      case ConnectionHealth.heartbeatTimeout:
        return 'No response from server, connection may be lost';
      case ConnectionHealth.disconnected:
        return 'Not connected to server';
    }
  }
}
