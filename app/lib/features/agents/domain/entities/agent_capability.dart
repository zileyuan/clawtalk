/// A capability entity representing a specific ability of an agent.
class AgentCapability {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic>? parameters;

  const AgentCapability({
    required this.id,
    required this.name,
    this.description,
    this.parameters,
  });

  /// Returns true if this capability has parameters defined.
  bool get hasParameters => parameters != null && parameters!.isNotEmpty;

  /// Returns the parameter keys if any.
  List<String> get parameterKeys => parameters?.keys.toList() ?? [];

  AgentCapability copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? parameters,
  }) {
    return AgentCapability(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentCapability &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        _mapEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    return Object.hash(id, name, description, _mapHash(parameters));
  }

  @override
  String toString() {
    return 'AgentCapability(id: $id, name: $name, hasParameters: $hasParameters)';
  }

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static int _mapHash(Map<String, dynamic>? map) {
    if (map == null) return 0;
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }

  /// Create AgentCapability from Gateway API response
  factory AgentCapability.fromGatewayJson(Map<String, dynamic> json) {
    return AgentCapability(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }
}
