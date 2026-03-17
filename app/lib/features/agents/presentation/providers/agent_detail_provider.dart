import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/agent.dart';
import '../../domain/entities/agent_capability.dart';
import 'agent_list_provider.dart';

/// Provider for the selected agent ID
final selectedAgentIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the selected agent details
final selectedAgentProvider = Provider<Agent?>((ref) {
  final agentId = ref.watch(selectedAgentIdProvider);
  if (agentId == null) return null;

  final agents = ref.watch(agentListProvider);
  return agents.firstWhere(
    (agent) => agent.id == agentId,
    orElse: () => throw Exception('Agent not found: $agentId'),
  );
});

/// Provider for agent detail state (loading, error, etc.)
final agentDetailStateProvider =
    StateNotifierProvider<AgentDetailNotifier, AgentDetailState>(
      (ref) => AgentDetailNotifier(ref),
    );

/// State for agent detail
class AgentDetailState {
  final bool isLoading;
  final String? error;
  final Agent? agent;
  final List<AgentCapability> capabilities;

  const AgentDetailState({
    this.isLoading = false,
    this.error,
    this.agent,
    this.capabilities = const [],
  });

  AgentDetailState copyWith({
    bool? isLoading,
    String? error,
    Agent? agent,
    List<AgentCapability>? capabilities,
  }) {
    return AgentDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      agent: agent ?? this.agent,
      capabilities: capabilities ?? this.capabilities,
    );
  }
}

/// Notifier for managing agent detail state
class AgentDetailNotifier extends StateNotifier<AgentDetailState> {
  final Ref _ref;

  AgentDetailNotifier(this._ref) : super(const AgentDetailState());

  /// Load agent details
  Future<void> loadAgent(String agentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate network request
      await Future.delayed(const Duration(milliseconds: 300));

      final agents = _ref.read(agentListProvider);
      final agent = agents.firstWhere(
        (a) => a.id == agentId,
        orElse: () => throw Exception('Agent not found'),
      );

      state = state.copyWith(
        isLoading: false,
        agent: agent,
        capabilities: agent.capabilities,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh agent details
  Future<void> refresh() async {
    final currentAgent = state.agent;
    if (currentAgent != null) {
      await loadAgent(currentAgent.id);
    }
  }

  /// Select an agent
  void selectAgent(String agentId) {
    _ref.read(selectedAgentIdProvider.notifier).state = agentId;
    loadAgent(agentId);
  }

  /// Clear selection
  void clearSelection() {
    _ref.read(selectedAgentIdProvider.notifier).state = null;
    state = const AgentDetailState();
  }

  /// Update agent status
  void updateAgentStatus(AgentStatus newStatus) {
    final currentAgent = state.agent;
    if (currentAgent == null) return;

    final updatedAgent = currentAgent.copyWith(status: newStatus);
    state = state.copyWith(agent: updatedAgent);

    // Also update in the main list
    _ref.read(agentListProvider.notifier).updateAgent(updatedAgent);
  }
}
