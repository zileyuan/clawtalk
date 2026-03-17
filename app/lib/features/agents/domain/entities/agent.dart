import 'agent_capability.dart';

/// Enum representing the current status of an agent.
enum AgentStatus { available, busy, offline, error }

/// An agent entity representing an AI agent that can be communicated with.
class Agent {
  final String id;
  final String name;
  final String? description;
  final List<AgentCapability> capabilities;
  final AgentStatus status;
  final DateTime? lastActive;

  const Agent({
    required this.id,
    required this.name,
    this.description,
    this.capabilities = const [],
    this.status = AgentStatus.offline,
    this.lastActive,
  });

  /// Returns true if the agent is available for interaction.
  bool get isAvailable => status == AgentStatus.available;

  /// Returns true if the agent is currently busy.
  bool get isBusy => status == AgentStatus.busy;

  /// Returns true if the agent is offline.
  bool get isOffline => status == AgentStatus.offline;

  /// Returns true if the agent has an error.
  bool get hasError => status == AgentStatus.error;

  /// Returns true if the agent has any capabilities defined.
  bool get hasCapabilities => capabilities.isNotEmpty;

  /// Returns true if the agent has a specific capability by name.
  bool hasCapability(String capabilityName) {
    return capabilities.any((c) => c.name == capabilityName);
  }

  Agent copyWith({
    String? id,
    String? name,
    String? description,
    List<AgentCapability>? capabilities,
    AgentStatus? status,
    DateTime? lastActive,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      capabilities: capabilities ?? this.capabilities,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Agent &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        _listEquals(other.capabilities, capabilities) &&
        other.status == status &&
        other.lastActive == lastActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      Object.hashAll(capabilities),
      status,
      lastActive,
    );
  }

  @override
  String toString() {
    return 'Agent(id: $id, name: $name, status: $status, '
        'capabilities: ${capabilities.length}, lastActive: $lastActive)';
  }

  static bool _listEquals(List<AgentCapability> a, List<AgentCapability> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
