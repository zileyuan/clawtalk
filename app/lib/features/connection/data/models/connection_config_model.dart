import '../../domain/entities/connection_config.dart';

/// Data model for connection configuration with JSON serialization.
///
/// Extends the domain [ConnectionConfig] entity and adds
/// serialization capabilities for persistence.
class ConnectionConfigModel extends ConnectionConfig {
  const ConnectionConfigModel({
    required super.id,
    required super.name,
    required super.host,
    required super.port,
    super.token,
    super.password,
    super.useTLS,
    required super.createdAt,
    super.lastUsed,
  });

  /// Create a model from the domain entity.
  factory ConnectionConfigModel.fromEntity(ConnectionConfig entity) {
    return ConnectionConfigModel(
      id: entity.id,
      name: entity.name,
      host: entity.host,
      port: entity.port,
      token: entity.token,
      password: entity.password,
      useTLS: entity.useTLS,
      createdAt: entity.createdAt,
      lastUsed: entity.lastUsed,
    );
  }

  /// Create a model from a JSON map.
  factory ConnectionConfigModel.fromJson(Map<String, dynamic> json) {
    return ConnectionConfigModel(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      token: json['token'] as String?,
      password: json['password'] as String?,
      useTLS: json['useTLS'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  /// Convert the model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'token': token,
      'password': password,
      'useTLS': useTLS,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  /// Create a copy with updated values.
  @override
  ConnectionConfigModel copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? token,
    String? password,
    bool? useTLS,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return ConnectionConfigModel(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      password: password ?? this.password,
      useTLS: useTLS ?? this.useTLS,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Create a copy without sensitive data for logging/debugging.
  ConnectionConfigModel toSafeCopy() {
    return ConnectionConfigModel(
      id: id,
      name: name,
      host: host,
      port: port,
      token: token != null ? '***' : null,
      password: password != null ? '***' : null,
      useTLS: useTLS,
      createdAt: createdAt,
      lastUsed: lastUsed,
    );
  }

  /// Convert a list of entities to models.
  static List<ConnectionConfigModel> fromEntityList(
    List<ConnectionConfig> entities,
  ) {
    return entities
        .map((entity) => ConnectionConfigModel.fromEntity(entity))
        .toList();
  }

  /// Convert a list of JSON maps to models.
  static List<ConnectionConfigModel> fromJsonList(
    List<Map<String, dynamic>> jsonList,
  ) {
    return jsonList
        .map((json) => ConnectionConfigModel.fromJson(json))
        .toList();
  }

  /// Convert a list of models to JSON maps.
  static List<Map<String, dynamic>> toJsonList(
    List<ConnectionConfigModel> models,
  ) {
    return models.map((model) => model.toJson()).toList();
  }

  @override
  String toString() {
    return 'ConnectionConfigModel(id: $id, name: $name, host: $host, port: $port, '
        'useTLS: $useTLS, createdAt: $createdAt, lastUsed: $lastUsed)';
  }
}
