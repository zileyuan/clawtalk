import 'dart:convert';

import '../acp_message.dart';
import '../acp_request.dart';
import '../acp_response.dart';
import '../acp_event.dart';

/// Message converter for JSON serialization/deserialization
///
/// Provides utilities for encoding and decoding ACP messages
/// to/from JSON format suitable for WebSocket transmission.
class MessageConverter {
  MessageConverter._();

  /// Encode a single message to JSON string
  static String encode(AcpMessage message) {
    return '${jsonEncode(message.toJson())}\n';
  }

  /// Encode a message without trailing newline
  static String encodeCompact(AcpMessage message) {
    return jsonEncode(message.toJson());
  }

  /// Decode a single JSON string to message
  static AcpMessage decode(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AcpMessage.fromJson(json);
  }

  /// Decode NDJSON (newline-delimited JSON) to message list
  static List<AcpMessage> decodeNdjson(String ndjson) {
    return ndjson
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => decode(line))
        .toList();
  }

  /// Try to decode a message, returning null on failure
  static AcpMessage? tryDecode(String jsonString) {
    try {
      return decode(jsonString);
    } catch (_) {
      return null;
    }
  }

  /// Encode a request message
  static String encodeRequest(AcpRequest request) => encode(request);

  /// Decode a response message
  static AcpResponse decodeResponse(String jsonString) {
    final message = decode(jsonString);
    if (message is! AcpResponse) {
      throw const FormatException('Expected response message');
    }
    return message;
  }

  /// Decode an event message
  static AcpEvent decodeEvent(String jsonString) {
    final message = decode(jsonString);
    if (message is! AcpEvent) {
      throw const FormatException('Expected event message');
    }
    return message;
  }

  /// Check if a JSON string represents a response
  static bool isResponse(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json['type'] == 'res';
    } catch (_) {
      return false;
    }
  }

  /// Check if a JSON string represents an event
  static bool isEvent(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json['type'] == 'event';
    } catch (_) {
      return false;
    }
  }

  /// Check if a JSON string represents a request
  static bool isRequest(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json['type'] == 'req';
    } catch (_) {
      return false;
    }
  }
}
