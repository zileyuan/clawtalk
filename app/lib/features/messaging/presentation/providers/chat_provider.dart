import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/content_block.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/session.dart';

/// Provider for the current chat state
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

/// Provider for the currently selected session
final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(chatProvider).currentSession;
});

/// Provider for the messages in the current chat
final chatMessagesProvider = Provider<List<Message>>((ref) {
  return ref.watch(chatProvider).messages;
});

/// Provider for the sending state
final isSendingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isSending;
});

/// Provider for the receiving state
final isReceivingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isReceiving;
});

/// State class for chat
class ChatState {
  final List<Message> messages;
  final Session? currentSession;
  final bool isSending;
  final bool isReceiving;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.currentSession,
    this.isSending = false,
    this.isReceiving = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    Session? currentSession,
    bool? isSending,
    bool? isReceiving,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      currentSession: currentSession ?? this.currentSession,
      isSending: isSending ?? this.isSending,
      isReceiving: isReceiving ?? this.isReceiving,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        other.messages == messages &&
        other.currentSession == currentSession &&
        other.isSending == isSending &&
        other.isReceiving == isReceiving &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(messages, currentSession, isSending, isReceiving, error);
  }
}

/// Notifier for managing chat state
class ChatNotifier extends StateNotifier<ChatState> {
  final _uuid = const Uuid();

  ChatNotifier() : super(const ChatState());

  /// Initialize chat with a session
  void initializeSession(Session session) {
    state = state.copyWith(currentSession: session, messages: [], error: null);
  }

  /// Clear current session
  void clearSession() {
    state = const ChatState();
  }

  /// Add a user message to the chat
  Future<void> sendMessage(String text) async {
    if (state.currentSession == null) return;
    if (text.trim().isEmpty) return;

    final message = Message(
      id: _uuid.v4(),
      sessionId: state.currentSession!.id,
      role: MessageRole.user,
      content: [
        ContentBlock(
          id: _uuid.v4(),
          type: ContentBlockType.text,
          content: text.trim(),
        ),
      ],
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, message],
      isSending: true,
      error: null,
    );

    // Simulate sending (will be replaced with actual API call)
    await Future.delayed(const Duration(milliseconds: 300));

    // Update message status to sent
    final updatedMessages = state.messages.map((m) {
      if (m.id == message.id) {
        return m.copyWith(status: MessageStatus.sent);
      }
      return m;
    }).toList();

    state = state.copyWith(messages: updatedMessages, isSending: false);
  }

  /// Add an assistant message (typically from streaming)
  void addAssistantMessage(Message message) {
    state = state.copyWith(
      messages: [...state.messages, message],
      isReceiving: false,
    );
  }

  /// Update the last assistant message (for streaming)
  void updateLastAssistantMessage(List<ContentBlock> content) {
    if (state.messages.isEmpty) return;

    final lastMessage = state.messages.last;
    if (lastMessage.role != MessageRole.assistant) return;

    final updatedMessage = lastMessage.copyWith(content: content);
    final updatedMessages = [...state.messages];
    updatedMessages[updatedMessages.length - 1] = updatedMessage;

    state = state.copyWith(messages: updatedMessages);
  }

  /// Mark as receiving streaming response
  void startReceiving() {
    state = state.copyWith(isReceiving: true);
  }

  /// Mark as done receiving
  void stopReceiving() {
    state = state.copyWith(isReceiving: false);
  }

  /// Update message status
  void updateMessageStatus(String messageId, MessageStatus status) {
    final updatedMessages = state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(status: status);
      }
      return m;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error, isSending: false, isReceiving: false);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Load messages (placeholder for actual API integration)
  Future<void> loadMessages(List<Message> messages) async {
    state = state.copyWith(messages: messages);
  }

  /// Clear all messages
  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}
