/// Gateway message types
enum GatewayMessageType {
  request,
  response,
  notification,
  event,
  ping,
  pong,
  error,
}

/// Base interface for all Gateway messages
abstract class GatewayMessage {
  /// Message type identifier
  String get type;

  /// Unique message identifier
  String get id;

  /// Serialize to JSON
  Map<String, dynamic> toJson();
}
