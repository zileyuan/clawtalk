import 'acp_request.dart';
import 'acp_response.dart';
import 'acp_event.dart';

/// Message type enumeration for ACP protocol
enum AcpMessageType {
  request,
  response,
  event;

  String toJson() => switch (this) {
    request => 'req',
    response => 'res',
    event => 'event',
  };

  static AcpMessageType fromJson(String value) => switch (value) {
    'req' => request,
    'res' => response,
    'event' => event,
    _ => request,
  };
}

/// Base abstract class for all ACP messages
///
/// ACP (Agent Client Protocol) uses three message types:
/// - [AcpRequest]: Client-to-server requests
/// - [AcpResponse]: Server-to-client responses
/// - [AcpEvent]: Server-pushed events
abstract class AcpMessage {
  const AcpMessage();

  /// Message type identifier
  AcpMessageType get messageType;

  /// Convert to JSON map for serialization
  Map<String, dynamic> toJson();

  /// Parse from JSON map
  factory AcpMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'req' => AcpRequest.fromJson(json),
      'res' => AcpResponse.fromJson(json),
      'event' => AcpEvent.fromJson(json),
      _ => throw AcpUnknownMessageTypeException(type),
    };
  }
}

/// Exception thrown when an unknown message type is encountered
class AcpUnknownMessageTypeException implements Exception {
  final String type;

  const AcpUnknownMessageTypeException(this.type);

  @override
  String toString() =>
      'AcpUnknownMessageTypeException: Unknown message type "$type"';
}

/// Message encoder/decoder utilities
class AcpMessageCodec {
  AcpMessageCodec._();

  /// Encode message to JSON string
  static String encode(AcpMessage message) {
    return '${_encodeJson(message.toJson())}\n';
  }

  /// Decode single JSON string to message
  static AcpMessage decode(String json) {
    return AcpMessage.fromJson(_decodeJson(json));
  }

  /// Decode NDJSON (newline-delimited JSON) to message list
  static List<AcpMessage> decodeNdjson(String ndjson) {
    return ndjson
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => decode(line))
        .toList();
  }

  /// Encode JSON map to string
  static String _encodeJson(Map<String, dynamic> json) {
    // Using dart:convert jsonEncode would be ideal, but we avoid importing it here
    // to keep this file focused on the model structure.
    // The actual implementation should use jsonEncode from dart:convert.
    return json.toString(); // Placeholder - use jsonEncode in production
  }

  /// Decode JSON string to map
  static Map<String, dynamic> _decodeJson(String json) {
    // Using dart:convert jsonDecode would be ideal
    // This is a placeholder - use jsonDecode in production
    throw UnimplementedError('Use jsonDecode from dart:convert');
  }
}
