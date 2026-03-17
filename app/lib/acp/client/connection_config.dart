import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

part 'connection_config.freezed.dart';
part 'connection_config.g.dart';

/// Configuration for ACP WebSocket connection
@freezed
class ConnectionConfig with _$ConnectionConfig {
  const factory ConnectionConfig({
    required String id,
    required String name,
    required String host,
    required int port,
    String? token,
    String? password,
    @Default(false) bool useTLS,
    @Default(AppConstants.connectionTimeout) Duration connectionTimeout,
    @Default(AppConstants.heartbeatInterval) Duration heartbeatInterval,
  }) = _ConnectionConfig;

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) =>
      _$ConnectionConfigFromJson(json);
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
