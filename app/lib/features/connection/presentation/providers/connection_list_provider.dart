import 'package:clawtalk/core/di/providers.dart';
import 'package:clawtalk/features/connection/domain/entities/connection_config.dart';
import 'package:clawtalk/features/connection/domain/repositories/connection_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// State for the connection list
class ConnectionListState {
  final List<ConnectionConfig> connections;
  final bool isLoading;
  final String? error;

  const ConnectionListState({
    this.connections = const [],
    this.isLoading = false,
    this.error,
  });

  ConnectionListState copyWith({
    List<ConnectionConfig>? connections,
    bool? isLoading,
    String? error,
  }) {
    return ConnectionListState(
      connections: connections ?? this.connections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing connection list state
class ConnectionListNotifier extends StateNotifier<ConnectionListState> {
  final ConnectionRepository _repository;

  ConnectionListNotifier({required ConnectionRepository repository})
    : _repository = repository,
      super(const ConnectionListState());

  /// Load all saved connections
  Future<void> loadConnections() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getAllConnections();

    if (result.failure != null) {
      state = state.copyWith(error: result.failure!.message, isLoading: false);
    } else {
      state = state.copyWith(
        connections: result.connections ?? [],
        isLoading: false,
      );
    }
  }

  /// Add a new connection
  Future<bool> addConnection(ConnectionConfig config) async {
    final failure = await _repository.saveConnection(config);

    if (failure != null) {
      state = state.copyWith(error: failure.message);
      return false;
    }

    final updatedConnections = [...state.connections, config];
    state = state.copyWith(connections: updatedConnections);
    return true;
  }

  /// Update an existing connection
  Future<bool> updateConnection(ConnectionConfig config) async {
    final failure = await _repository.updateConnection(config);

    if (failure != null) {
      state = state.copyWith(error: failure.message);
      return false;
    }

    final updatedConnections = state.connections.map((c) {
      return c.id == config.id ? config : c;
    }).toList();
    state = state.copyWith(connections: updatedConnections);
    return true;
  }

  /// Delete a connection
  Future<bool> deleteConnection(String id) async {
    final failure = await _repository.deleteConnection(id);

    if (failure != null) {
      state = state.copyWith(error: failure.message);
      return false;
    }

    final updatedConnections = state.connections
        .where((c) => c.id != id)
        .toList();
    state = state.copyWith(connections: updatedConnections);
    return true;
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for connection list state
final connectionListProvider =
    StateNotifierProvider<ConnectionListNotifier, ConnectionListState>(
      (ref) => ConnectionListNotifier(
        repository: ref.watch(connectionRepositoryProvider),
      ),
    );

/// Provider for sorted connections (by last used)
final sortedConnectionsProvider = Provider<List<ConnectionConfig>>((ref) {
  final state = ref.watch(connectionListProvider);
  return [...state.connections]..sort((a, b) {
    if (a.lastUsed == null && b.lastUsed == null) return 0;
    if (a.lastUsed == null) return 1;
    if (b.lastUsed == null) return -1;
    return b.lastUsed!.compareTo(a.lastUsed!);
  });
});

/// Provider to check if there are any connections
final hasConnectionsProvider = Provider<bool>((ref) {
  final state = ref.watch(connectionListProvider);
  return state.connections.isNotEmpty;
});
