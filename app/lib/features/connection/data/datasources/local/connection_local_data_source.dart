import 'dart:convert';

import 'package:clawtalk/core/constants/storage_keys.dart';
import 'package:clawtalk/core/data/datasources/local/preferences_service.dart';
import 'package:clawtalk/core/data/datasources/local/secure_storage_service.dart';
import 'package:clawtalk/core/errors/exceptions.dart';
import 'package:clawtalk/features/connection/data/models/connection_config_model.dart';

/// Local data source for connection configurations.
///
/// Handles persistence of connection configs using:
/// - [PreferencesService] for non-sensitive connection data
/// - [SecureStorageService] for sensitive data (tokens, passwords)
abstract class ConnectionLocalDataSource {
  /// Get all saved connection configurations.
  Future<List<ConnectionConfigModel>> getAllConnections();

  /// Get a connection configuration by ID.
  Future<ConnectionConfigModel?> getConnectionById(String id);

  /// Get the last used connection configuration.
  Future<ConnectionConfigModel?> getLastConnection();

  /// Save a connection configuration.
  Future<void> saveConnection(ConnectionConfigModel connection);

  /// Update an existing connection configuration.
  Future<void> updateConnection(ConnectionConfigModel connection);

  /// Delete a connection configuration.
  Future<void> deleteConnection(String id);

  /// Set the last used connection.
  Future<void> setLastConnection(String connectionId);

  /// Clear all connection configurations.
  Future<void> clearAllConnections();

  /// Save sensitive credentials for a connection.
  Future<void> saveCredentials({
    required String connectionId,
    String? token,
    String? password,
  });

  /// Get sensitive credentials for a connection.
  Future<({String? token, String? password})> getCredentials(
    String connectionId,
  );

  /// Delete credentials for a connection.
  Future<void> deleteCredentials(String connectionId);
}

/// Implementation of [ConnectionLocalDataSource] using preferences and secure storage.
class ConnectionLocalDataSourceImpl implements ConnectionLocalDataSource {
  final PreferencesService _preferences;
  final SecureStorageService _secureStorage;

  ConnectionLocalDataSourceImpl({
    required PreferencesService preferences,
    required SecureStorageService secureStorage,
  }) : _preferences = preferences,
       _secureStorage = secureStorage;

  @override
  Future<List<ConnectionConfigModel>> getAllConnections() async {
    try {
      final jsonStrings = _preferences.readStringList(StorageKeys.connections);

      if (jsonStrings == null || jsonStrings.isEmpty) {
        return [];
      }

      final connections = jsonStrings.map((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ConnectionConfigModel.fromJson(json);
      }).toList();

      // Load credentials from secure storage
      final connectionsWithCredentials = await Future.wait(
        connections.map((connection) async {
          final credentials = await getCredentials(connection.id);
          return connection.copyWith(
            token: credentials.token,
            password: credentials.password,
          );
        }),
      );

      return connectionsWithCredentials;
    } catch (e) {
      throw CacheException(message: 'Failed to load connections: $e', code: 1);
    }
  }

  @override
  Future<ConnectionConfigModel?> getConnectionById(String id) async {
    try {
      final connections = await getAllConnections();
      return connections.cast<ConnectionConfigModel?>().firstWhere(
        (connection) => connection?.id == id,
        orElse: () => null,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to get connection by ID: $e',
        code: 2,
      );
    }
  }

  @override
  Future<ConnectionConfigModel?> getLastConnection() async {
    try {
      final lastConnectionId = _preferences.readString(
        StorageKeys.lastConnection,
      );

      if (lastConnectionId == null) {
        return null;
      }

      return await getConnectionById(lastConnectionId);
    } catch (e) {
      throw CacheException(
        message: 'Failed to get last connection: $e',
        code: 3,
      );
    }
  }

  @override
  Future<void> saveConnection(ConnectionConfigModel connection) async {
    try {
      // Save credentials to secure storage
      await saveCredentials(
        connectionId: connection.id,
        token: connection.token,
        password: connection.password,
      );

      // Create safe connection without sensitive data
      // Note: We can't use copyWith(token: null) because ?? operator keeps original value
      final safeConnection = ConnectionConfigModel(
        id: connection.id,
        name: connection.name,
        host: connection.host,
        port: connection.port,
        token: null, // Explicitly set to null
        password: null, // Explicitly set to null
        useTLS: connection.useTLS,
        createdAt: connection.createdAt,
        lastUsed: connection.lastUsed,
      );

      final connections = await _getRawConnections();
      final jsonStrings = [...connections, jsonEncode(safeConnection.toJson())];

      await _preferences.writeStringList(StorageKeys.connections, jsonStrings);
    } catch (e) {
      throw CacheException(message: 'Failed to save connection: $e', code: 4);
    }
  }

  @override
  Future<void> updateConnection(ConnectionConfigModel connection) async {
    try {
      // Update credentials in secure storage
      await saveCredentials(
        connectionId: connection.id,
        token: connection.token,
        password: connection.password,
      );

      // Update connection in preferences
      final connections = await _getRawConnections();
      final index = connections.indexWhere((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return json['id'] == connection.id;
      });

      if (index == -1) {
        throw const CacheException(
          message: 'Connection not found for update',
          code: 5,
        );
      }

      // Create safe connection without sensitive data
      final safeConnection = ConnectionConfigModel(
        id: connection.id,
        name: connection.name,
        host: connection.host,
        port: connection.port,
        token: null, // Explicitly set to null
        password: null, // Explicitly set to null
        useTLS: connection.useTLS,
        createdAt: connection.createdAt,
        lastUsed: connection.lastUsed,
      );
      connections[index] = jsonEncode(safeConnection.toJson());

      await _preferences.writeStringList(StorageKeys.connections, connections);
    } catch (e) {
      throw CacheException(message: 'Failed to update connection: $e', code: 6);
    }
  }

  @override
  Future<void> deleteConnection(String id) async {
    try {
      // Delete credentials from secure storage
      await deleteCredentials(id);

      // Delete connection from preferences
      final connections = await _getRawConnections();
      connections.removeWhere((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return json['id'] == id;
      });

      await _preferences.writeStringList(StorageKeys.connections, connections);

      // Clear last connection if it was this one
      final lastConnectionId = _preferences.readString(
        StorageKeys.lastConnection,
      );
      if (lastConnectionId == id) {
        await _preferences.remove(StorageKeys.lastConnection);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to delete connection: $e', code: 7);
    }
  }

  @override
  Future<void> setLastConnection(String connectionId) async {
    try {
      await _preferences.writeString(StorageKeys.lastConnection, connectionId);
    } catch (e) {
      throw CacheException(
        message: 'Failed to set last connection: $e',
        code: 8,
      );
    }
  }

  @override
  Future<void> clearAllConnections() async {
    try {
      // Get all connection IDs to delete their credentials
      final connections = await getAllConnections();
      for (final connection in connections) {
        await deleteCredentials(connection.id);
      }

      // Clear connection list
      await _preferences.remove(StorageKeys.connections);
      await _preferences.remove(StorageKeys.lastConnection);
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear all connections: $e',
        code: 9,
      );
    }
  }

  @override
  Future<void> saveCredentials({
    required String connectionId,
    String? token,
    String? password,
  }) async {
    try {
      // Try secure storage first
      if (token != null) {
        await _secureStorage.write(
          StorageKeys.connectionToken(connectionId),
          token,
        );
      } else {
        await _secureStorage.delete(StorageKeys.connectionToken(connectionId));
      }

      if (password != null) {
        await _secureStorage.write(
          StorageKeys.connectionPassword(connectionId),
          password,
        );
      } else {
        await _secureStorage.delete(
          StorageKeys.connectionPassword(connectionId),
        );
      }
    } catch (e) {
      // Fallback to preferences if secure storage fails (e.g., macOS Keychain issues in debug)
      // This is less secure but allows the app to function during development
      if (token != null) {
        await _preferences.writeString(
          StorageKeys.connectionToken(connectionId),
          token,
        );
      } else {
        await _preferences.remove(StorageKeys.connectionToken(connectionId));
      }

      if (password != null) {
        await _preferences.writeString(
          StorageKeys.connectionPassword(connectionId),
          password,
        );
      } else {
        await _preferences.remove(StorageKeys.connectionPassword(connectionId));
      }
    }
  }

  @override
  Future<({String? token, String? password})> getCredentials(
    String connectionId,
  ) async {
    try {
      // Try secure storage first
      final token = await _secureStorage.read(
        StorageKeys.connectionToken(connectionId),
      );
      final password = await _secureStorage.read(
        StorageKeys.connectionPassword(connectionId),
      );

      return (token: token, password: password);
    } catch (e) {
      // Fallback to preferences
      final token = _preferences.readString(
        StorageKeys.connectionToken(connectionId),
      );
      final password = _preferences.readString(
        StorageKeys.connectionPassword(connectionId),
      );

      return (token: token, password: password);
    }
  }

  @override
  Future<void> deleteCredentials(String connectionId) async {
    try {
      // Try secure storage first
      await _secureStorage.delete(StorageKeys.connectionToken(connectionId));
      await _secureStorage.delete(StorageKeys.connectionPassword(connectionId));
    } catch (e) {
      // Fallback to preferences
      await _preferences.remove(StorageKeys.connectionToken(connectionId));
      await _preferences.remove(StorageKeys.connectionPassword(connectionId));
    }
  }

  /// Get raw connection JSON strings from preferences.
  Future<List<String>> _getRawConnections() async {
    return _preferences.readStringList(StorageKeys.connections) ?? [];
  }
}
