import 'package:clawtalk/core/errors/failures.dart';
import 'package:clawtalk/features/connection/domain/entities/connection_config.dart';

/// Repository interface for connection management.
///
/// Follows the Repository pattern from Clean Architecture.
/// This is the contract that the data layer must implement.
///
/// Uses Dart records for result types: (failure: null, ...) indicates success.
abstract class ConnectionRepository {
  /// Get all saved connection configurations.
  Future<({Failure? failure, List<ConnectionConfig>? connections})>
  getAllConnections();

  /// Get a connection configuration by ID.
  Future<({Failure? failure, ConnectionConfig? connection})> getConnectionById(
    String id,
  );

  /// Get the last used connection configuration.
  Future<({Failure? failure, ConnectionConfig? connection})>
  getLastConnection();

  /// Save a new connection configuration.
  /// Returns null on success, Failure on error.
  Future<Failure?> saveConnection(ConnectionConfig connection);

  /// Update an existing connection configuration.
  /// Returns null on success, Failure on error.
  Future<Failure?> updateConnection(ConnectionConfig connection);

  /// Delete a connection configuration.
  /// Returns null on success, Failure on error.
  Future<Failure?> deleteConnection(String id);

  /// Set the last used connection.
  /// Returns null on success, Failure on error.
  Future<Failure?> setLastConnection(String connectionId);

  /// Clear all connection configurations.
  /// Returns null on success, Failure on error.
  Future<Failure?> clearAllConnections();

  /// Validate connection credentials.
  Future<({Failure? failure, bool isValid})> validateConnection(
    ConnectionConfig connection,
  );

  /// Test connection to the server.
  Future<({Failure? failure, bool isConnected})> testConnection(
    ConnectionConfig connection,
  );
}
