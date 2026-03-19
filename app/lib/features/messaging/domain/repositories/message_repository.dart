import 'package:clawtalk/core/errors/failures.dart';
import 'package:clawtalk/features/messaging/data/models/message_model.dart';
import 'package:clawtalk/features/messaging/data/models/session_model.dart';

/// Repository interface for messaging.
///
/// Follows the Repository pattern from Clean Architecture.
/// This is the contract that the data layer must implement.
abstract class MessageRepository {
  // Sessions
  /// Get all sessions for a connection.
  Future<({Failure? failure, List<SessionModel>? sessions})> getSessions(
    String connectionId,
  );

  /// Get a session by ID.
  Future<({Failure? failure, SessionModel? session})> getSessionById(
    String sessionId,
  );

  /// Create a new session.
  Future<Failure?> createSession(SessionModel session);

  /// Update a session.
  Future<Failure?> updateSession(SessionModel session);

  /// Delete a session and its messages.
  Future<Failure?> deleteSession(String sessionId);

  // Messages
  /// Get messages for a session with pagination.
  Future<({Failure? failure, List<MessageModel>? messages})> getMessages(
    String sessionId, {
    int? limit,
    String? beforeId,
  });

  /// Get a message by ID.
  Future<({Failure? failure, MessageModel? message})> getMessageById(
    String messageId,
  );

  /// Send a message.
  Future<Failure?> sendMessage(MessageModel message);

  /// Update a message status.
  Future<Failure?> updateMessageStatus(String messageId, MessageStatus status);

  /// Delete a message.
  Future<Failure?> deleteMessage(String messageId);

  /// Clear all messages in a session.
  Future<Failure?> clearSessionMessages(String sessionId);

  /// Clear all messaging data.
  Future<Failure?> clearAll();
}
