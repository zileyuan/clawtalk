/// Agent status enum
enum AgentStatus {
  available,
  busy,
  offline,
  error;

  String toJson() => name;

  static AgentStatus fromJson(String value) => AgentStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AgentStatus.offline,
  );

  static AgentStatus fromString(String value) => fromJson(value);
}

/// Agent capability flags
class AgentCapabilities {
  final bool supportsStreaming;
  final bool supportsImages;
  final bool supportsAudio;
  final bool supportsTools;
  final bool supportsFiles;
  final bool supportsCodeExecution;
  final List<String>? customCapabilities;

  const AgentCapabilities({
    this.supportsStreaming = false,
    this.supportsImages = false,
    this.supportsAudio = false,
    this.supportsTools = false,
    this.supportsFiles = false,
    this.supportsCodeExecution = false,
    this.customCapabilities,
  });

  AgentCapabilities copyWith({
    bool? supportsStreaming,
    bool? supportsImages,
    bool? supportsAudio,
    bool? supportsTools,
    bool? supportsFiles,
    bool? supportsCodeExecution,
    List<String>? customCapabilities,
  }) {
    return AgentCapabilities(
      supportsStreaming: supportsStreaming ?? this.supportsStreaming,
      supportsImages: supportsImages ?? this.supportsImages,
      supportsAudio: supportsAudio ?? this.supportsAudio,
      supportsTools: supportsTools ?? this.supportsTools,
      supportsFiles: supportsFiles ?? this.supportsFiles,
      supportsCodeExecution:
          supportsCodeExecution ?? this.supportsCodeExecution,
      customCapabilities: customCapabilities ?? this.customCapabilities,
    );
  }

  factory AgentCapabilities.fromJson(Map<String, dynamic> json) =>
      AgentCapabilities(
        supportsStreaming: json['supportsStreaming'] as bool? ?? false,
        supportsImages: json['supportsImages'] as bool? ?? false,
        supportsAudio: json['supportsAudio'] as bool? ?? false,
        supportsTools: json['supportsTools'] as bool? ?? false,
        supportsFiles: json['supportsFiles'] as bool? ?? false,
        supportsCodeExecution: json['supportsCodeExecution'] as bool? ?? false,
        customCapabilities: (json['customCapabilities'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    if (supportsStreaming) 'supportsStreaming': supportsStreaming,
    if (supportsImages) 'supportsImages': supportsImages,
    if (supportsAudio) 'supportsAudio': supportsAudio,
    if (supportsTools) 'supportsTools': supportsTools,
    if (supportsFiles) 'supportsFiles': supportsFiles,
    if (supportsCodeExecution) 'supportsCodeExecution': supportsCodeExecution,
    if (customCapabilities != null) 'customCapabilities': customCapabilities,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCapabilities &&
          runtimeType == other.runtimeType &&
          supportsStreaming == other.supportsStreaming &&
          supportsImages == other.supportsImages &&
          supportsAudio == other.supportsAudio &&
          supportsTools == other.supportsTools &&
          supportsFiles == other.supportsFiles &&
          supportsCodeExecution == other.supportsCodeExecution &&
          _listEquals(customCapabilities, other.customCapabilities);

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    supportsStreaming,
    supportsImages,
    supportsAudio,
    supportsTools,
    supportsFiles,
    supportsCodeExecution,
    customCapabilities,
  );
}

/// Agent information model
///
/// Represents an available agent with its capabilities and status.
class AgentInfo {
  /// Unique agent identifier
  final String id;

  /// Human-readable name
  final String name;

  /// Agent description
  final String? description;

  /// Agent version
  final String? version;

  /// Current agent status
  final AgentStatus status;

  /// Agent capabilities
  final AgentCapabilities capabilities;

  /// Agent model name (e.g., 'claude-3-opus')
  final String? model;

  /// Provider name
  final String? provider;

  /// Additional metadata
  final Map<String, dynamic>? meta;

  /// Icon URL or identifier
  final String? icon;

  /// Tags for categorization
  final List<String> tags;

  const AgentInfo({
    required this.id,
    required this.name,
    this.description,
    this.version,
    this.status = AgentStatus.available,
    this.capabilities = const AgentCapabilities(),
    this.model,
    this.provider,
    this.meta,
    this.icon,
    this.tags = const [],
  });

  AgentInfo copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    AgentStatus? status,
    AgentCapabilities? capabilities,
    String? model,
    String? provider,
    Map<String, dynamic>? meta,
    String? icon,
    List<String>? tags,
  }) {
    return AgentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      status: status ?? this.status,
      capabilities: capabilities ?? this.capabilities,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      meta: meta ?? this.meta,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
    );
  }

  factory AgentInfo.fromJson(Map<String, dynamic> json) => AgentInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    version: json['version'] as String?,
    status: json['status'] != null
        ? AgentStatus.fromJson(json['status'] as String)
        : AgentStatus.available,
    capabilities: json['capabilities'] != null
        ? AgentCapabilities.fromJson(
            json['capabilities'] as Map<String, dynamic>,
          )
        : const AgentCapabilities(),
    model: json['model'] as String?,
    provider: json['provider'] as String?,
    meta: json['meta'] as Map<String, dynamic>?,
    icon: json['icon'] as String?,
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (version != null) 'version': version,
    'status': status.toJson(),
    'capabilities': capabilities.toJson(),
    if (model != null) 'model': model,
    if (provider != null) 'provider': provider,
    if (meta != null) 'meta': meta,
    if (icon != null) 'icon': icon,
    if (tags.isNotEmpty) 'tags': tags,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          version == other.version &&
          status == other.status &&
          capabilities == other.capabilities &&
          model == other.model &&
          provider == other.provider &&
          _mapEquals(meta, other.meta) &&
          icon == other.icon &&
          _listEquals(tags, other.tags);

  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    version,
    status,
    capabilities,
    model,
    provider,
    meta,
    icon,
    tags,
  );
}

/// Extension for AgentInfo convenience methods
extension AgentInfoExtensions on AgentInfo {
  /// Check if agent is available
  bool get isAvailable => status == AgentStatus.available;

  /// Check if agent is busy
  bool get isBusy => status == AgentStatus.busy;

  /// Check if agent is offline
  bool get isOffline => status == AgentStatus.offline;

  /// Check if agent supports streaming responses
  bool get canStream => capabilities.supportsStreaming;

  /// Check if agent can process images
  bool get canProcessImages => capabilities.supportsImages;

  /// Check if agent can process audio
  bool get canProcessAudio => capabilities.supportsAudio;

  /// Check if agent can use tools
  bool get canUseTools => capabilities.supportsTools;
}
