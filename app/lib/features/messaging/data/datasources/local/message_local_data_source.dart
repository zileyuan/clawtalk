import 'dart:convert';
import 'package:clawtalk/core/constants/storage_keys.dart';
import 'package:clawtalk/core/data/datasources/local/preferences_service.dart';
import 'package:clawtalk/core/errors/exceptions.dart';
import 'package:clawtalk/features/messaging/data/models/message_model.dart';
import 'package:clawtalk/features/messaging/data/models/session_model.dart';

/// Local data source for messages and sessions.
///
/// Handles persistence of messaging data using preferences.
/// Messages are stored per session for offline access.
abstract class MessageLocalDataSource {
  // Sessions
  /// Get all sessions for a connection.
  Future<List<SessionModel>> getSessions(String connectionId);

  /// Get a session by ID.
  Future<SessionModel?> getSessionById(String sessionId);

  /// Save a session.
  Future<void> saveSession(SessionModel session);

  /// Update a session.
  Future<void> updateSession(SessionModel session);

  /// Delete a session and its messages.
  Future<void> deleteSession(String sessionId);

  // Messages
  /// Get messages for a session.
  Future<List<MessageModel>> getMessages(
    String sessionId, {
    int? limit,
    String? beforeId,
  });

  /// Get a message by ID.
  Future<MessageModel?> getMessageById(String messageId);

  /// Save a message.
  Future<void> saveMessage(MessageModel message);

  /// Update a message.
  Future<void> updateMessage(MessageModel message);

  /// Delete a message.
  Future<void> deleteMessage(String messageId);

  /// Clear all messages for a session.
  Future<void> clearSessionMessages(String sessionId);

  /// Clear all messages and sessions.
  Future<void> clearAll();
}

/// Implementation of [MessageLocalDataSource] using preferences.
class MessageLocalDataSourceImpl implements MessageLocalDataSource {
  final PreferencesService _preferences;

  MessageLocalDataSourceImpl({required PreferencesService preferences})
    : _preferences = preferences;

  // Session storage key
  String _sessionKey(String connectionId) =>
      '${StorageKeys.sessionHistory}_$connectionId';

  // Message storage key
  String _messageKey(String sessionId) => 'clawtalk_messages_$sessionId';

  @override
  Future<List<SessionModel>> getSessions(String connectionId) async {
    try {
      final jsonStrings = _preferences.readStringList(
        _sessionKey(connectionId),
      );

      if (jsonStrings == null || jsonStrings.isEmpty) {
        return [];
      }

      return jsonStrings.map((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return SessionModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load sessions: $e', code: 1);
    }
  }

  @override
  Future<SessionModel?> getSessionById(String sessionId) async {
    try {
      // We need to search through all connections' sessions
      // For now, we'll use a direct key approach
      final sessionJson = _preferences.readJson('clawtalk_session_$sessionId');
      if (sessionJson == null) return null;
      return SessionModel.fromJson(sessionJson);
    } catch (e) {
      throw CacheException(message: 'Failed to get session: $e', code: 2);
    }
  }

  @override
  Future<void> saveSession(SessionModel session) async {
    try {
      // Save to connection's session list
      final key = _sessionKey(session.connectionId);
      final sessions = await getSessions(session.connectionId);
      sessions.insert(0, session); // Add to beginning

      final jsonStrings = sessions.map((s) => jsonEncode(s.toJson())).toList();
      await _preferences.writeStringList(key, jsonStrings);

      // Also save individual session for quick lookup
      await _preferences.writeJson(
        'clawtalk_session_${session.id}',
        session.toJson(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save session: $e', code: 3);
    }
  }

  @override
  Future<void> updateSession(SessionModel session) async {
    try {
      final key = _sessionKey(session.connectionId);
      final sessions = await getSessions(session.connectionId);
      final index = sessions.indexWhere((s) => s.id == session.id);

      if (index == -1) {
        throw const CacheException(
          message: 'Session not found for update',
          code: 4,
        );
      }

      sessions[index] = session;
      final jsonStrings = sessions.map((s) => jsonEncode(s.toJson())).toList();
      await _preferences.writeStringList(key, jsonStrings);

      // Update individual session
      await _preferences.writeJson(
        'clawtalk_session_${session.id}',
        session.toJson(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to update session: $e', code: 5);
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      final session = await getSessionById(sessionId);
      if (session == null) return;

      // Delete messages first
      await clearSessionMessages(sessionId);

      // Remove from connection's session list
      final key = _sessionKey(session.connectionId);
      final sessions = await getSessions(session.connectionId);
      sessions.removeWhere((s) => s.id == sessionId);

      final jsonStrings = sessions.map((s) => jsonEncode(s.toJson())).toList();
      await _preferences.writeStringList(key, jsonStrings);

      // Delete individual session
      await _preferences.remove('clawtalk_session_$sessionId');
    } catch (e) {
      throw CacheException(message: 'Failed to delete session: $e', code: 6);
    }
  }

  @override
  Future<List<MessageModel>> getMessages(
    String sessionId, {
    int? limit,
    String? beforeId,
  }) async {
    try {
      final key = _messageKey(sessionId);
      final jsonStrings = _preferences.readStringList(key);

      if (jsonStrings == null || jsonStrings.isEmpty) {
        return [];
      }

      var messages = jsonStrings.map((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return MessageModel.fromJson(json);
      }).toList();

      // Sort by creation date (newest first)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply pagination
      if (beforeId != null) {
        final beforeIndex = messages.indexWhere((m) => m.id == beforeId);
        if (beforeIndex != -1) {
          messages = messages.sublist(beforeIndex + 1);
        }
      }

      if (limit != null && messages.length > limit) {
        messages = messages.sublist(0, limit);
      }

      return messages;
    } catch (e) {
      throw CacheException(message: 'Failed to load messages: $e', code: 7);
    }
  }

  @override
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      final messageJson = _preferences.readJson('clawtalk_message_$messageId');
      if (messageJson == null) return null;
      return MessageModel.fromJson(messageJson);
    } catch (e) {
      throw CacheException(message: 'Failed to get message: $e', code: 8);
    }
  }

  @override
  Future<void> saveMessage(MessageModel message) async {
    try {
      // Add to session's message list
      final key = _messageKey(message.sessionId);
      final messages = await getMessages(message.sessionId);
      messages.insert(0, message); // Add to beginning

      final jsonStrings = messages.map((m) => jsonEncode(m.toJson())).toList();
      await _preferences.writeStringList(key, jsonStrings);

      // Save individual message for quick lookup
      await _preferences.writeJson(
        'clawtalk_message_${message.id}',
        message.toJson(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save message: $e', code: 9);
    }
  }

  @override
  Future<void> updateMessage(MessageModel message) async {
    try {
      final key = _messageKey(message.sessionId);
      final messages = await getMessages(message.sessionId);
      final index = messages.indexWhere((m) => m.id == message.id);

      if (index == -1) {
        throw const CacheException(
          message: 'Message not found for update',
          code: 10,
        );
      }

      messages[index] = message;
      final jsonStrings = messages.map((m) => jsonEncode(m.toJson())).toList();
      await _preferences.writeStringList(key, jsonStrings);

      // Update individual message
      await _preferences.writeJson(
        'clawtalk_message_${message.id}',
        message.toJson(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to update message: $e', code: 11);
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final message = await getMessageById(messageId);
      if (message == null) return;

      // Remove from session's message list
      final key = _messageKey(message.sessionId);
      final messages = await getMessages(message.sessionId);
      messages.removeWhere((m) => m.id == messageId);

      final jsonStrings = messages.map((m) => jsonEncode(m.toJson())).toList();
      await _preferences.writeStringList(key, jsonStrings);

      // Delete individual message
      await _preferences.remove('clawtalk_message_$messageId');
    } catch (e) {
      throw CacheException(message: 'Failed to delete message: $e', code: 12);
    }
  }

  @override
  Future<void> clearSessionMessages(String sessionId) async {
    try {
      // Get all messages to delete individual entries
      final messages = await getMessages(sessionId);
      for (final message in messages) {
        await _preferences.remove('clawtalk_message_${message.id}');
      }

      // Clear session message list
      await _preferences.remove(_messageKey(sessionId));
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear session messages: $e',
        code: 13,
      );
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      // Clear all keys that start with our prefixes
      final keys = _preferences.keys;
      for (final key in keys) {
        if (key.startsWith('clawtalk_messages_') ||
            key.startsWith('clawtalk_message_') ||
            key.startsWith('clawtalk_session_') ||
            key.startsWith('${StorageKeys.sessionHistory}_')) {
          await _preferences.remove(key);
        }
      }
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear all messages: $e',
        code: 14,
      );
    }
  }
}
