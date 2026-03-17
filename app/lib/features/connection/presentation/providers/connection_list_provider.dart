import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/connection_config.dart';

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
  ConnectionListNotifier() : super(const ConnectionListState());

  /// Load all saved connections
  Future<void> loadConnections() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Replace with actual repository call
      // final connections = await _repository.getAllConnections();
      // Simulating data for now
      await Future.delayed(const Duration(milliseconds: 300));
      final connections = <ConnectionConfig>[];
      state = state.copyWith(connections: connections, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load connections: $e',
        isLoading: false,
      );
    }
  }

  /// Add a new connection
  Future<void> addConnection(ConnectionConfig config) async {
    try {
      // TODO: Replace with actual repository call
      // await _repository.saveConnection(config);
      final updatedConnections = [...state.connections, config];
      state = state.copyWith(connections: updatedConnections);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add connection: $e');
    }
  }

  /// Update an existing connection
  Future<void> updateConnection(ConnectionConfig config) async {
    try {
      // TODO: Replace with actual repository call
      // await _repository.updateConnection(config);
      final updatedConnections = state.connections.map((c) {
        return c.id == config.id ? config : c;
      }).toList();
      state = state.copyWith(connections: updatedConnections);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update connection: $e');
    }
  }

  /// Delete a connection
  Future<void> deleteConnection(String id) async {
    try {
      // TODO: Replace with actual repository call
      // await _repository.deleteConnection(id);
      final updatedConnections = state.connections
          .where((c) => c.id != id)
          .toList();
      state = state.copyWith(connections: updatedConnections);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete connection: $e');
    }
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for connection list state
final connectionListProvider =
    StateNotifierProvider<ConnectionListNotifier, ConnectionListState>(
      (ref) => ConnectionListNotifier(),
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
