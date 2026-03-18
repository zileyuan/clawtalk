import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

/// Configuration for ACP WebSocket connection
class ConnectionConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? token;
  final String? password;
  final bool useTLS;
  final Duration connectionTimeout;
  final Duration heartbeatInterval;

  const ConnectionConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.token,
    this.password,
    this.useTLS = false,
    this.connectionTimeout = AppConstants.connectionTimeout,
    this.heartbeatInterval = AppConstants.heartbeatInterval,
  });

  ConnectionConfig copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? token,
    String? password,
    bool? useTLS,
    Duration? connectionTimeout,
    Duration? heartbeatInterval,
  }) {
    return ConnectionConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      password: password ?? this.password,
      useTLS: useTLS ?? this.useTLS,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
    );
  }

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) =>
      ConnectionConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: json['port'] as int,
        token: json['token'] as String?,
        password: json['password'] as String?,
        useTLS: json['useTLS'] as bool? ?? false,
        connectionTimeout: json['connectionTimeout'] != null
            ? Duration(milliseconds: json['connectionTimeout'] as int)
            : AppConstants.connectionTimeout,
        heartbeatInterval: json['heartbeatInterval'] != null
            ? Duration(milliseconds: json['heartbeatInterval'] as int)
            : AppConstants.heartbeatInterval,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    if (token != null) 'token': token,
    if (password != null) 'password': password,
    'useTLS': useTLS,
    'connectionTimeout': connectionTimeout.inMilliseconds,
    'heartbeatInterval': heartbeatInterval.inMilliseconds,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionConfig &&
          id == other.id &&
          name == other.name &&
          host == other.host &&
          port == other.port &&
          token == other.token &&
          password == other.password &&
          useTLS == other.useTLS &&
          connectionTimeout == other.connectionTimeout &&
          heartbeatInterval == other.heartbeatInterval;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    host,
    port,
    token,
    password,
    useTLS,
    connectionTimeout,
    heartbeatInterval,
  );
}

/// Extension for ConnectionConfig utilities
extension ConnectionConfigX on ConnectionConfig {
  /// Create default connection configuration
  static ConnectionConfig defaultConfig({
    String? name,
    String? host,
    int? port,
    String? token,
    String? password,
  }) {
    return ConnectionConfig(
      id: const Uuid().v4(),
      name: name ?? 'Default Connection',
      host: host ?? ApiConstants.defaultHost,
      port: port ?? ApiConstants.defaultPort,
      token: token,
      password: password,
    );
  }

  /// Build WebSocket URI from config
  Uri get wsUri {
    final scheme = useTLS ? 'wss' : 'ws';
    return Uri.parse('$scheme://$host:$port${ApiConstants.wsPath}');
  }

  /// Build HTTP URI from config
  Uri httpUri(String path) {
    final scheme = useTLS ? 'https' : 'http';
    return Uri.parse('$scheme://$host:$port$path');
  }

  /// Check if config has authentication
  bool get hasAuth => token != null || password != null;

  /// Check if config is valid
  bool get isValid {
    return host.isNotEmpty && port > 0 && port <= 65535;
  }

  /// Create a copy with updated host
  ConnectionConfig withHost(String newHost) => copyWith(host: newHost);

  /// Create a copy with updated port
  ConnectionConfig withPort(int newPort) => copyWith(port: newPort);

  /// Create a copy with updated token
  ConnectionConfig withToken(String? newToken) => copyWith(token: newToken);

  /// Create a copy with updated password
  ConnectionConfig withPassword(String? newPassword) =>
      copyWith(password: newPassword);

  /// Create a copy with TLS enabled/disabled
  ConnectionConfig withTLS(bool enabled) => copyWith(useTLS: enabled);

  /// Display string for UI
  String get displayString => '$name ($host:$port)';

  /// Short display string for compact UI
  String get shortDisplayString => '$host:$port';
}
