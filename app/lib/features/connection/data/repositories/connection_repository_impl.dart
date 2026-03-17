import '../../../core/errors/error_handler.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../datasources/local/connection_local_data_source.dart';
import '../models/connection_config_model.dart';
import '../../domain/entities/connection_config.dart';
import '../../domain/repositories/connection_repository.dart';

/// Implementation of [ConnectionRepository].
///
/// Uses local data source for persistence and will use
/// remote data source for connection testing when implemented.
class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionLocalDataSource _localDataSource;

  ConnectionRepositoryImpl({required ConnectionLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<({Failure? failure, List<ConnectionConfig>? connections})>
  getAllConnections() async {
    try {
      final connections = await _localDataSource.getAllConnections();
      return (failure: null, connections: connections);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), connections: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to load connections: $e'),
        connections: null,
      );
    }
  }

  @override
  Future<({Failure? failure, ConnectionConfig? connection})> getConnectionById(
    String id,
  ) async {
    try {
      final connection = await _localDataSource.getConnectionById(id);
      return (failure: null, connection: connection);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), connection: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to get connection: $e'),
        connection: null,
      );
    }
  }

  @override
  Future<({Failure? failure, ConnectionConfig? connection})>
  getLastConnection() async {
    try {
      final connection = await _localDataSource.getLastConnection();
      return (failure: null, connection: connection);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), connection: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to get last connection: $e'),
        connection: null,
      );
    }
  }

  @override
  Future<Failure?> saveConnection(ConnectionConfig connection) async {
    try {
      final model = ConnectionConfigModel.fromEntity(connection);
      await _localDataSource.saveConnection(model);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to save connection: $e');
    }
  }

  @override
  Future<Failure?> updateConnection(ConnectionConfig connection) async {
    try {
      final model = ConnectionConfigModel.fromEntity(connection);
      await _localDataSource.updateConnection(model);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update connection: $e');
    }
  }

  @override
  Future<Failure?> deleteConnection(String id) async {
    try {
      await _localDataSource.deleteConnection(id);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to delete connection: $e');
    }
  }

  @override
  Future<Failure?> setLastConnection(String connectionId) async {
    try {
      await _localDataSource.setLastConnection(connectionId);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to set last connection: $e');
    }
  }

  @override
  Future<Failure?> clearAllConnections() async {
    try {
      await _localDataSource.clearAllConnections();
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to clear connections: $e');
    }
  }

  @override
  Future<({Failure? failure, bool isValid})> validateConnection(
    ConnectionConfig connection,
  ) async {
    try {
      // Basic validation
      if (connection.host.isEmpty) {
        return (
          failure: const ValidationFailure(message: 'Host cannot be empty'),
          isValid: false,
        );
      }

      if (connection.port <= 0 || connection.port > 65535) {
        return (
          failure: const ValidationFailure(
            message: 'Port must be between 1 and 65535',
          ),
          isValid: false,
        );
      }

      return (failure: null, isValid: true);
    } catch (e) {
      return (
        failure: ValidationFailure(message: 'Validation failed: $e'),
        isValid: false,
      );
    }
  }

  @override
  Future<({Failure? failure, bool isConnected})> testConnection(
    ConnectionConfig connection,
  ) async {
    try {
      // TODO: Implement actual connection test with remote data source
      // For now, just validate the connection parameters
      final result = await validateConnection(connection);

      if (result.failure != null) {
        return (failure: result.failure, isConnected: false);
      }

      return (failure: null, isConnected: true);
    } catch (e) {
      return (
        failure: ConnectionFailure(message: 'Connection test failed: $e'),
        isConnected: false,
      );
    }
  }
}
