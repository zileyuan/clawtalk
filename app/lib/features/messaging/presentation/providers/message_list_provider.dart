import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/message.dart';

/// Provider for message list with pagination
final messageListProvider =
    StateNotifierProvider.family<MessageListNotifier, MessageListState, String>(
      (ref, sessionId) {
        return MessageListNotifier(sessionId: sessionId);
      },
    );

/// State class for message list with pagination
class MessageListState {
  final List<Message> messages;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final int pageSize;
  final String? error;
  final bool isInitialLoad;

  const MessageListState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.pageSize = 20,
    this.error,
    this.isInitialLoad = true,
  });

  MessageListState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    int? pageSize,
    String? error,
    bool? isInitialLoad,
  }) {
    return MessageListState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      error: error,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
    );
  }

  /// Get messages sorted by creation time (oldest first)
  List<Message> get sortedMessages {
    final sorted = List<Message>.from(messages);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  /// Check if there are no messages
  bool get isEmpty => messages.isEmpty && !isLoading;

  /// Check if there's an error
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageListState &&
        other.messages == messages &&
        other.isLoading == isLoading &&
        other.hasMore == hasMore &&
        other.currentPage == currentPage &&
        other.pageSize == pageSize &&
        other.error == error &&
        other.isInitialLoad == isInitialLoad;
  }

  @override
  int get hashCode {
    return Object.hash(
      messages,
      isLoading,
      hasMore,
      currentPage,
      pageSize,
      error,
      isInitialLoad,
    );
  }
}

/// Notifier for managing paginated message list
class MessageListNotifier extends StateNotifier<MessageListState> {
  final String sessionId;

  MessageListNotifier({required this.sessionId})
    : super(const MessageListState());

  /// Load initial messages
  Future<void> loadInitialMessages() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null, currentPage: 0);

    try {
      // TODO: Replace with actual API call
      // final response = await api.getMessages(
      //   sessionId: sessionId,
      //   page: 0,
      //   pageSize: state.pageSize,
      // );

      // Simulated delay
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, return empty list - actual implementation will fetch from API
      const messages = <Message>[];

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMore: messages.length >= state.pageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: $e',
        isInitialLoad: false,
      );
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final nextPage = state.currentPage + 1;

      // TODO: Replace with actual API call
      // final response = await api.getMessages(
      //   sessionId: sessionId,
      //   page: nextPage,
      //   pageSize: state.pageSize,
      // );

      // Simulated delay
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, return empty list - actual implementation will fetch from API
      const newMessages = <Message>[];

      if (newMessages.isEmpty) {
        state = state.copyWith(isLoading: false, hasMore: false);
      } else {
        state = state.copyWith(
          messages: [...newMessages, ...state.messages],
          isLoading: false,
          hasMore: newMessages.length >= state.pageSize,
          currentPage: nextPage,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more messages: $e',
      );
    }
  }

  /// Add a new message to the list
  void addMessage(Message message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  /// Update an existing message
  void updateMessage(Message updatedMessage) {
    final updatedMessages = state.messages.map((m) {
      return m.id == updatedMessage.id ? updatedMessage : m;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  /// Remove a message
  void removeMessage(String messageId) {
    final updatedMessages = state.messages
        .where((m) => m.id != messageId)
        .toList();
    state = state.copyWith(messages: updatedMessages);
  }

  /// Refresh the list
  Future<void> refresh() async {
    await loadInitialMessages();
  }

  /// Clear all messages
  void clear() {
    state = const MessageListState();
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
