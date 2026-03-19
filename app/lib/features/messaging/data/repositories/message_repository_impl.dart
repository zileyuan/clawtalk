import 'package:clawtalk/core/errors/error_handler.dart';
import 'package:clawtalk/core/errors/exceptions.dart';
import 'package:clawtalk/core/errors/failures.dart';
import 'package:clawtalk/features/messaging/data/datasources/local/message_local_data_source.dart';
import 'package:clawtalk/features/messaging/data/models/message_model.dart';
import 'package:clawtalk/features/messaging/data/models/session_model.dart';
import 'package:clawtalk/features/messaging/domain/repositories/message_repository.dart';

/// Implementation of [MessageRepository].
///
/// Uses local data source for persistence.
class MessageRepositoryImpl implements MessageRepository {
  final MessageLocalDataSource _localDataSource;

  MessageRepositoryImpl({required MessageLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<({Failure? failure, List<SessionModel>? sessions})> getSessions(
    String connectionId,
  ) async {
    try {
      final sessions = await _localDataSource.getSessions(connectionId);
      return (failure: null, sessions: sessions);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), sessions: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to load sessions: $e'),
        sessions: null,
      );
    }
  }

  @override
  Future<({Failure? failure, SessionModel? session})> getSessionById(
    String sessionId,
  ) async {
    try {
      final session = await _localDataSource.getSessionById(sessionId);
      return (failure: null, session: session);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), session: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to get session: $e'),
        session: null,
      );
    }
  }

  @override
  Future<Failure?> createSession(SessionModel session) async {
    try {
      await _localDataSource.saveSession(session);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to create session: $e');
    }
  }

  @override
  Future<Failure?> updateSession(SessionModel session) async {
    try {
      await _localDataSource.updateSession(session);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update session: $e');
    }
  }

  @override
  Future<Failure?> deleteSession(String sessionId) async {
    try {
      await _localDataSource.deleteSession(sessionId);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to delete session: $e');
    }
  }

  @override
  Future<({Failure? failure, List<MessageModel>? messages})> getMessages(
    String sessionId, {
    int? limit,
    String? beforeId,
  }) async {
    try {
      final messages = await _localDataSource.getMessages(
        sessionId,
        limit: limit,
        beforeId: beforeId,
      );
      return (failure: null, messages: messages);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), messages: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to load messages: $e'),
        messages: null,
      );
    }
  }

  @override
  Future<({Failure? failure, MessageModel? message})> getMessageById(
    String messageId,
  ) async {
    try {
      final message = await _localDataSource.getMessageById(messageId);
      return (failure: null, message: message);
    } on CacheException catch (e) {
      return (failure: exceptionToFailure(e), message: null);
    } catch (e) {
      return (
        failure: CacheFailure(message: 'Failed to get message: $e'),
        message: null,
      );
    }
  }

  @override
  Future<Failure?> sendMessage(MessageModel message) async {
    try {
      await _localDataSource.saveMessage(message);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to send message: $e');
    }
  }

  @override
  Future<Failure?> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    try {
      final message = await _localDataSource.getMessageById(messageId);
      if (message == null) {
        return const CacheFailure(message: 'Message not found');
      }

      final updatedMessage = message.copyWith(status: status);
      await _localDataSource.updateMessage(updatedMessage);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to update message status: $e');
    }
  }

  @override
  Future<Failure?> deleteMessage(String messageId) async {
    try {
      await _localDataSource.deleteMessage(messageId);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to delete message: $e');
    }
  }

  @override
  Future<Failure?> clearSessionMessages(String sessionId) async {
    try {
      await _localDataSource.clearSessionMessages(sessionId);
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to clear session messages: $e');
    }
  }

  @override
  Future<Failure?> clearAll() async {
    try {
      await _localDataSource.clearAll();
      return null;
    } on CacheException catch (e) {
      return exceptionToFailure(e);
    } catch (e) {
      return CacheFailure(message: 'Failed to clear all messages: $e');
    }
  }
}
