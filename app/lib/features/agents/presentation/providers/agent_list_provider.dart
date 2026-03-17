import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/agent.dart';
import '../../domain/entities/agent_capability.dart';

/// Provider for the list of available agents
final agentListProvider = StateNotifierProvider<AgentListNotifier, List<Agent>>(
  (ref) => AgentListNotifier(),
);

/// Provider for filtered agents based on search query
final filteredAgentListProvider = Provider<List<Agent>>((ref) {
  final agents = ref.watch(agentListProvider);
  final searchQuery = ref.watch(agentSearchProvider);

  if (searchQuery.isEmpty) {
    return agents;
  }

  final query = searchQuery.toLowerCase();
  return agents.where((agent) {
    return agent.name.toLowerCase().contains(query) ||
        (agent.description?.toLowerCase().contains(query) ?? false) ||
        agent.capabilities.any((cap) => cap.name.toLowerCase().contains(query));
  }).toList();
});

/// Provider for the search query
final agentSearchProvider = StateProvider<String>((ref) => '');

/// Provider for the selected filter category
final agentFilterCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for available agents only
final availableAgentsProvider = Provider<List<Agent>>((ref) {
  final agents = ref.watch(agentListProvider);
  return agents.where((agent) => agent.isAvailable).toList();
});

/// Provider for agents grouped by category
final agentsByCategoryProvider = Provider<Map<String, List<Agent>>>((ref) {
  final agents = ref.watch(agentListProvider);
  final grouped = <String, List<Agent>>{};

  for (final agent in agents) {
    for (final capability in agent.capabilities) {
      final category = _getCategoryFromCapability(capability);
      grouped.putIfAbsent(category, () => []).add(agent);
    }
  }

  // Remove duplicates
  for (final entry in grouped.entries) {
    grouped[entry.key] = entry.value.toSet().toList();
  }

  return grouped;
});

String _getCategoryFromCapability(AgentCapability capability) {
  // Simple categorization based on capability name
  final name = capability.name.toLowerCase();
  if (name.contains('code') || name.contains('program')) {
    return 'Development';
  } else if (name.contains('write') || name.contains('text')) {
    return 'Writing';
  } else if (name.contains('image') || name.contains('visual')) {
    return 'Visual';
  } else if (name.contains('data') || name.contains('analy')) {
    return 'Analysis';
  }
  return 'General';
}

/// Notifier for managing the agent list
class AgentListNotifier extends StateNotifier<List<Agent>> {
  AgentListNotifier() : super([]) {
    _loadMockAgents();
  }

  void _loadMockAgents() {
    // Mock data for development
    state = [
      Agent(
        id: 'agent-1',
        name: 'Code Assistant',
        description: 'Helps with coding tasks and debugging',
        status: AgentStatus.available,
        capabilities: [
          const AgentCapability(
            id: 'cap-1',
            name: 'Code Generation',
            description: 'Generate code in various languages',
          ),
          const AgentCapability(
            id: 'cap-2',
            name: 'Code Review',
            description: 'Review and suggest improvements',
          ),
        ],
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'agent-2',
        name: 'Creative Writer',
        description: 'Assists with creative writing and storytelling',
        status: AgentStatus.available,
        capabilities: [
          const AgentCapability(
            id: 'cap-3',
            name: 'Story Writing',
            description: 'Create engaging stories',
          ),
          const AgentCapability(
            id: 'cap-4',
            name: 'Content Creation',
            description: 'Generate various content types',
          ),
        ],
        lastActive: DateTime.now(),
      ),
      Agent(
        id: 'agent-3',
        name: 'Data Analyst',
        description: 'Analyzes data and creates visualizations',
        status: AgentStatus.busy,
        capabilities: [
          const AgentCapability(
            id: 'cap-5',
            name: 'Data Analysis',
            description: 'Analyze datasets',
          ),
          const AgentCapability(
            id: 'cap-6',
            name: 'Visualization',
            description: 'Create charts and graphs',
          ),
        ],
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Agent(
        id: 'agent-4',
        name: 'Image Creator',
        description: 'Generates and edits images',
        status: AgentStatus.offline,
        capabilities: [
          const AgentCapability(
            id: 'cap-7',
            name: 'Image Generation',
            description: 'Generate images from descriptions',
          ),
        ],
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  /// Refresh the agent list
  Future<void> refresh() async {
    // Simulate network request
    await Future.delayed(const Duration(milliseconds: 500));
    _loadMockAgents();
  }

  /// Add a new agent to the list
  void addAgent(Agent agent) {
    state = [...state, agent];
  }

  /// Remove an agent from the list
  void removeAgent(String agentId) {
    state = state.where((agent) => agent.id != agentId).toList();
  }

  /// Update an agent in the list
  void updateAgent(Agent updatedAgent) {
    state = state.map((agent) {
      return agent.id == updatedAgent.id ? updatedAgent : agent;
    }).toList();
  }

  /// Set the search query
  void setSearchQuery(String query) {
    // This is handled by agentSearchProvider
  }
}
