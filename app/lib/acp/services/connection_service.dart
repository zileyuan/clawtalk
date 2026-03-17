import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../client/acp_client.dart';
import '../client/acp_client_impl.dart';
import '../client/connection_config.dart';
import '../client/connection_state.dart';
import '../exceptions/acp_exception.dart';

/// Connection service provider
final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return ConnectionService();
});

/// High-level connection service for managing ACP connections
class ConnectionService {
  final Logger _logger;
  AcpClient? _client;
  ConnectionConfig? _activeConfig;

  final _stateController = StreamController<ConnectionState>.broadcast();
  final _configController = StreamController<ConnectionConfig?>.broadcast();

  StreamSubscription<ConnectionState>? _stateSubscription;

  ConnectionService({Logger? logger}) : _logger = logger ?? Logger();

  /// Stream of connection state changes
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// Current connection state
  ConnectionState get state =>
      _client?.currentState ?? ConnectionState.initial();

  /// Currently active connection config
  ConnectionConfig? get activeConfig => _activeConfig;

  /// Stream of active config changes
  Stream<ConnectionConfig?> get configStream => _configController.stream;

  /// Whether currently connected
  bool get isConnected => _client?.isConnected ?? false;

  /// Whether currently connecting
  bool get isConnecting => _client?.isConnecting ?? false;

  /// Connect with given configuration
  Future<void> connect(ConnectionConfig config) async {
    if (_client?.isConnected == true) {
      await disconnect();
    }

    _activeConfig = config;
    _configController.add(config);

    _client = AcpClientImpl();
    _stateSubscription = _client!.connectionState.listen(
      (state) => _stateController.add(state),
      onError: (error) => _logger.e('Connection error: $error'),
    );

    await _client!.connect(config);
    await _saveLastConnection(config);
  }

  /// Disconnect current connection
  Future<void> disconnect() async {
    await _stateSubscription?.cancel();
    _stateSubscription = null;

    await _client?.disconnect();
    _client = null;
    _activeConfig = null;
    _configController.add(null);
  }

  /// Get the underlying client (throws if not connected)
  AcpClient get client {
    if (_client == null || !_client!.isConnected) {
      throw AcpStateException.notConnected();
    }
    return _client!;
  }

  /// Load saved connection configurations
  Future<List<ConnectionConfig>> loadSavedConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList(_savedConnectionsKey) ?? [];

    return configsJson
        .map((json) {
          try {
            return ConnectionConfig.fromJson(
              Map<String, dynamic>.from(
                // ignore: avoid_dynamic_calls
                Map<String, dynamic>.from({}).runtimeType == json.runtimeType
                    ? json as Map<String, dynamic>
                    : {},
              ),
            );
          } catch (e) {
            _logger.e('Failed to parse saved connection: $e');
            return null;
          }
        })
        .whereType<ConnectionConfig>()
        .toList();
  }

  /// Save a connection configuration
  Future<void> saveConnection(ConnectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await loadSavedConnections();

    // Remove existing config with same ID
    configs.removeWhere((c) => c.id == config.id);
    configs.add(config);

    await prefs.setStringList(
      _savedConnectionsKey,
      configs.map((c) => c.toJson().toString()).toList(),
    );
  }

  /// Delete a saved connection configuration
  Future<void> deleteConnection(String configId) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await loadSavedConnections();
    configs.removeWhere((c) => c.id == configId);

    await prefs.setStringList(
      _savedConnectionsKey,
      configs.map((c) => c.toJson().toString()).toList(),
    );
  }

  /// Get the last used connection
  Future<ConnectionConfig?> getLastConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_lastConnectionKey);

    if (lastId == null) return null;

    final configs = await loadSavedConnections();
    return configs.firstWhere(
      (c) => c.id == lastId,
      orElse: () => configs.firstOrNull as ConnectionConfig,
    );
  }

  /// Save the last used connection
  Future<void> _saveLastConnection(ConnectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastConnectionKey, config.id);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _configController.close();
  }

  static const _savedConnectionsKey = 'acp_saved_connections';
  static const _lastConnectionKey = 'acp_last_connection';
}

/// Connection pool for managing multiple connections
class ConnectionPool {
  final Logger _logger;
  final Map<String, AcpClient> _clients = {};
  final int maxConnections;

  ConnectionPool({this.maxConnections = 5, Logger? logger})
    : _logger = logger ?? Logger();

  /// Get a client by ID
  AcpClient? getClient(String id) => _clients[id];

  /// Create a new connection
  Future<AcpClient> createConnection(String id, ConnectionConfig config) async {
    if (_clients.containsKey(id)) {
      throw StateError('Connection $id already exists');
    }

    if (_clients.length >= maxConnections) {
      throw StateError('Maximum connections reached');
    }

    final client = AcpClientImpl();
    await client.connect(config);
    _clients[id] = client;

    return client;
  }

  /// Remove a connection
  Future<void> removeConnection(String id) async {
    final client = _clients.remove(id);
    await client?.close();
  }

  /// Close all connections
  Future<void> closeAll() async {
    await Future.wait(_clients.values.map((client) => client.close()));
    _clients.clear();
  }

  /// Get all active connection IDs
  List<String> get activeConnectionIds => _clients.keys.toList();

  /// Get connection count
  int get connectionCount => _clients.length;
}
