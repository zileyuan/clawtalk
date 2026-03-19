/// Gateway protocol constants
class GatewayConstants {
  GatewayConstants._();

  /// Default Gateway port
  static const int defaultPort = 18789;

  /// WebSocket path
  static const String wsPath = '/ws';

  /// Maximum payload size (25 MB)
  static const int maxPayloadBytes = 25 * 1024 * 1024;

  /// Handshake timeout
  static const Duration handshakeTimeout = Duration(seconds: 10);

  /// Tick/heartbeat interval
  static const Duration tickInterval = Duration(seconds: 30);

  /// Minimum protocol version
  static const int minProtocol = 3;

  /// Maximum protocol version
  static const int maxProtocol = 3;

  /// Default client ID
  static const String clientId = 'clawtalk-client';

  /// Client name
  static const String clientName = 'ClawTalk';

  /// Client version
  static const String clientVersion = '1.0.0';
}
