import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_info.freezed.dart';
part 'agent_info.g.dart';

/// Agent status enum
enum AgentStatus {
  @JsonValue('available')
  available,
  @JsonValue('busy')
  busy,
  @JsonValue('offline')
  offline,
  @JsonValue('error')
  error;

  static AgentStatus fromString(String value) {
    return AgentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AgentStatus.offline,
    );
  }
}

/// Agent capability flags
@freezed
class AgentCapabilities with _$AgentCapabilities {
  const factory AgentCapabilities({
    @Default(false) bool supportsStreaming,
    @Default(false) bool supportsImages,
    @Default(false) bool supportsAudio,
    @Default(false) bool supportsTools,
    @Default(false) bool supportsFiles,
    @Default(false) bool supportsCodeExecution,
    List<String>? customCapabilities,
  }) = _AgentCapabilities;

  factory AgentCapabilities.fromJson(Map<String, dynamic> json) =>
      _$AgentCapabilitiesFromJson(json);
}

/// Agent information model
///
/// Represents an available agent with its capabilities and status.
@freezed
class AgentInfo with _$AgentInfo {
  const factory AgentInfo({
    /// Unique agent identifier
    required String id,

    /// Human-readable name
    required String name,

    /// Agent description
    String? description,

    /// Agent version
    String? version,

    /// Current agent status
    @Default(AgentStatus.available) AgentStatus status,

    /// Agent capabilities
    @Default(AgentCapabilities()) AgentCapabilities capabilities,

    /// Agent model name (e.g., 'claude-3-opus')
    String? model,

    /// Provider name
    String? provider,

    /// Additional metadata
    Map<String, dynamic>? meta,

    /// Icon URL or identifier
    String? icon,

    /// Tags for categorization
    @Default([]) List<String> tags,
  }) = _AgentInfo;

  factory AgentInfo.fromJson(Map<String, dynamic> json) =>
      _$AgentInfoFromJson(json);
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
