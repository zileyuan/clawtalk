import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../client/acp_client.dart';
import '../client/connection_config.dart';
import '../client/connection_state.dart';
import '../exceptions/acp_exception.dart';

/// Reconnection service provider
final reconnectionServiceProvider = Provider<ReconnectionService>((ref) {
  return ReconnectionService();
});

/// Service for managing automatic reconnection with exponential backoff
class ReconnectionService {
  final Logger _logger;

  Timer? _reconnectTimer;
  AcpClient? _client;
  ConnectionConfig? _config;

  int _attemptCount = 0;
  int _maxAttempts;
  Duration _initialDelay;
  Duration _maxDelay;
  double _backoffMultiplier;

  StreamSubscription<ConnectionState>? _stateSubscription;

  final _stateController = StreamController<ReconnectionState>.broadcast();
  final _attemptController = StreamController<ReconnectionAttempt>.broadcast();

  ReconnectionService({
    Logger? logger,
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    double backoffMultiplier = 2.0,
  }) : _logger = logger ?? Logger(),
       _maxAttempts = maxAttempts,
       _initialDelay = initialDelay,
       _maxDelay = maxDelay,
       _backoffMultiplier = backoffMultiplier;

  /// Stream of reconnection state changes
  Stream<ReconnectionState> get stateStream => _stateController.stream;

  /// Stream of reconnection attempts
  Stream<ReconnectionAttempt> get attemptStream => _attemptController.stream;

  /// Current reconnection state
  ReconnectionState get state => _client?.isConnected == true
      ? ReconnectionState.connected
      : _reconnectTimer != null
      ? ReconnectionState.reconnecting
      : ReconnectionState.idle;

  /// Current attempt count
  int get attemptCount => _attemptCount;

  /// Whether reconnection is in progress
  bool get isReconnecting => _reconnectTimer != null;

  /// Initialize with an ACP client
  void initialize(AcpClient client, ConnectionConfig config) {
    _client = client;
    _config = config;

    // Listen for connection state changes
    _stateSubscription?.cancel();
    _stateSubscription = client.connectionState.listen(_handleConnectionState);
  }

  /// Enable auto-reconnection
  void enable() {
    if (_client == null || _config == null) {
      throw StateError(
        'Client and config must be set before enabling reconnection',
      );
    }
    _logger.i('Auto-reconnection enabled');
  }

  /// Disable auto-reconnection
  void disable() {
    cancel();
    _logger.i('Auto-reconnection disabled');
  }

  /// Update reconnection parameters
  void updateParameters({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
  }) {
    if (maxAttempts != null) _maxAttempts = maxAttempts;
    if (initialDelay != null) _initialDelay = initialDelay;
    if (maxDelay != null) _maxDelay = maxDelay;
    if (backoffMultiplier != null) _backoffMultiplier = backoffMultiplier;
  }

  /// Handle connection state changes
  void _handleConnectionState(ConnectionState state) {
    if (state.isDisconnected || state.hasError) {
      // Connection lost, start reconnection
      if (!_isManualDisconnect) {
        _scheduleReconnect();
      }
    } else if (state.isConnected) {
      // Connected, reset attempt count
      _resetAttempts();
      _notifyState(ReconnectionState.connected);
    }
  }

  bool _isManualDisconnect = false;

  /// Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (_attemptCount >= _maxAttempts) {
      _logger.w('Max reconnection attempts reached');
      _notifyState(ReconnectionState.failed);
      return;
    }

    _cancelTimer();
    _notifyState(ReconnectionState.reconnecting);

    final delay = _calculateDelay();
    _logger.i(
      'Scheduling reconnect attempt ${_attemptCount + 1} in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, _attemptReconnect);
  }

  /// Calculate delay with exponential backoff and jitter
  Duration _calculateDelay() {
    // Exponential backoff
    final exponentialDelay =
        _initialDelay * pow(_backoffMultiplier, _attemptCount);

    // Add jitter (±25%) to prevent thundering herd
    final random = Random();
    final jitter = exponentialDelay * (0.75 + random.nextDouble() * 0.5);

    // Cap at max delay
    final finalDelay = Duration(
      milliseconds: min(jitter.inMilliseconds, _maxDelay.inMilliseconds),
    );

    return finalDelay;
  }

  /// Attempt to reconnect
  Future<void> _attemptReconnect() async {
    if (_client == null || _config == null) {
      _logger.e('Cannot reconnect: client or config not set');
      return;
    }

    _attemptCount++;
    final attempt = ReconnectionAttempt(
      attemptNumber: _attemptCount,
      maxAttempts: _maxAttempts,
      timestamp: DateTime.now(),
    );

    _notifyAttempt(attempt);
    _logger.i('Reconnection attempt $_attemptCount/$_maxAttempts');

    try {
      await _client!.connect(_config!);

      if (_client!.isConnected) {
        _resetAttempts();
        _notifyState(ReconnectionState.connected);
        _logger.i('Reconnection successful');
      }
    } on AcpException catch (e) {
      _logger.e('Reconnection attempt failed: $e');

      if (_attemptCount < _maxAttempts) {
        _scheduleReconnect();
      } else {
        _notifyState(ReconnectionState.failed);
      }
    } catch (e) {
      _logger.e('Unexpected error during reconnection: $e');

      if (_attemptCount < _maxAttempts) {
        _scheduleReconnect();
      } else {
        _notifyState(ReconnectionState.failed);
      }
    }
  }

  /// Reset attempt counter
  void _resetAttempts() {
    _attemptCount = 0;
    _cancelTimer();
  }

  /// Cancel reconnection timer
  void _cancelTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Cancel reconnection
  void cancel() {
    _cancelTimer();
    _resetAttempts();
    _notifyState(ReconnectionState.idle);
  }

  /// Trigger manual reconnection
  Future<void> reconnectNow() async {
    _cancelTimer();
    await _attemptReconnect();
  }

  /// Notify state change
  void _notifyState(ReconnectionState state) {
    _stateController.add(state);
  }

  /// Notify attempt
  void _notifyAttempt(ReconnectionAttempt attempt) {
    _attemptController.add(attempt);
  }

  /// Dispose resources
  void dispose() {
    cancel();
    _stateSubscription?.cancel();
    _stateController.close();
    _attemptController.close();
  }
}

/// Reconnection state
enum ReconnectionState {
  /// Not currently reconnecting
  idle,

  /// Currently attempting to reconnect
  reconnecting,

  /// Successfully reconnected
  connected,

  /// Reconnection failed after max attempts
  failed,
}

/// Reconnection attempt information
class ReconnectionAttempt {
  final int attemptNumber;
  final int maxAttempts;
  final DateTime timestamp;
  final String? error;

  ReconnectionAttempt({
    required this.attemptNumber,
    required this.maxAttempts,
    required this.timestamp,
    this.error,
  });

  /// Whether this was the last attempt
  bool get isLastAttempt => attemptNumber >= maxAttempts;

  /// Get remaining attempts
  int get remainingAttempts => maxAttempts - attemptNumber;

  /// Get progress as a fraction (0.0 to 1.0)
  double get progress => attemptNumber / maxAttempts;
}

/// Extension for ReconnectionState
extension ReconnectionStateX on ReconnectionState {
  /// Get display string
  String get displayString {
    switch (this) {
      case ReconnectionState.idle:
        return 'Idle';
      case ReconnectionState.reconnecting:
        return 'Reconnecting';
      case ReconnectionState.connected:
        return 'Connected';
      case ReconnectionState.failed:
        return 'Failed';
    }
  }

  /// Whether reconnection is in progress
  bool get isReconnecting => this == ReconnectionState.reconnecting;

  /// Whether reconnection was successful
  bool get isConnected => this == ReconnectionState.connected;

  /// Whether reconnection failed
  bool get isFailed => this == ReconnectionState.failed;
}
