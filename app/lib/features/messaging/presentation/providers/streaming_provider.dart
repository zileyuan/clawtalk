import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/content_block.dart';
import '../../domain/entities/message.dart';
import 'chat_provider.dart';

/// Provider for streaming response state
final streamingProvider =
    StateNotifierProvider<StreamingNotifier, StreamingState>(
      (ref) => StreamingNotifier(ref: ref),
    );

/// Provider for the current streaming content
final streamingContentProvider = Provider<List<ContentBlock>>((ref) {
  return ref.watch(streamingProvider).contentBlocks;
});

/// Provider for streaming text (concatenated from content blocks)
final streamingTextProvider = Provider<String>((ref) {
  final contentBlocks = ref.watch(streamingContentProvider);
  return contentBlocks
      .where((block) => block.type == ContentBlockType.text)
      .map((block) => block.content)
      .join('');
});

/// Provider for streaming state
final isStreamingProvider = Provider<bool>((ref) {
  return ref.watch(streamingProvider).isStreaming;
});

/// State class for streaming
class StreamingState {
  final bool isStreaming;
  final List<ContentBlock> contentBlocks;
  final String? error;
  final DateTime? startedAt;
  final String? sessionId;

  const StreamingState({
    this.isStreaming = false,
    this.contentBlocks = const [],
    this.error,
    this.startedAt,
    this.sessionId,
  });

  StreamingState copyWith({
    bool? isStreaming,
    List<ContentBlock>? contentBlocks,
    String? error,
    DateTime? startedAt,
    String? sessionId,
  }) {
    return StreamingState(
      isStreaming: isStreaming ?? this.isStreaming,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      error: error,
      startedAt: startedAt ?? this.startedAt,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  /// Get the current accumulated text
  String get currentText {
    return contentBlocks
        .where((block) => block.type == ContentBlockType.text)
        .map((block) => block.content)
        .join('');
  }

  /// Check if there's any content
  bool get hasContent => contentBlocks.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamingState &&
        other.isStreaming == isStreaming &&
        other.contentBlocks == contentBlocks &&
        other.error == error &&
        other.startedAt == startedAt &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    return Object.hash(isStreaming, contentBlocks, error, startedAt, sessionId);
  }
}

/// Notifier for managing streaming responses
class StreamingNotifier extends StateNotifier<StreamingState> {
  final Ref ref;
  final _uuid = const Uuid();
  StreamSubscription<String>? _streamSubscription;

  StreamingNotifier({required this.ref}) : super(const StreamingState());

  /// Start streaming a response
  void startStreaming({required String sessionId}) {
    // Cancel any existing stream
    _streamSubscription?.cancel();

    state = StreamingState(
      isStreaming: true,
      contentBlocks: const [],
      sessionId: sessionId,
      startedAt: DateTime.now(),
    );

    // Notify chat provider that we're receiving
    ref.read(chatProvider.notifier).startReceiving();
  }

  /// Append text chunk to the streaming content
  void appendTextChunk(String chunk) {
    if (!state.isStreaming) return;

    // Find existing text block or create new one
    final textBlocks = state.contentBlocks
        .where((block) => block.type == ContentBlockType.text)
        .toList();

    List<ContentBlock> updatedBlocks;
    if (textBlocks.isNotEmpty) {
      // Update the last text block
      final lastTextBlock = textBlocks.last;
      final updatedBlock = lastTextBlock.copyWith(
        content: lastTextBlock.content + chunk,
      );

      updatedBlocks = state.contentBlocks.map((block) {
        return block.id == lastTextBlock.id ? updatedBlock : block;
      }).toList();
    } else {
      // Create new text block
      final newBlock = ContentBlock(
        id: _uuid.v4(),
        type: ContentBlockType.text,
        content: chunk,
      );
      updatedBlocks = [...state.contentBlocks, newBlock];
    }

    state = state.copyWith(contentBlocks: updatedBlocks);
  }

  /// Add a content block (for non-text content like images, code, etc.)
  void addContentBlock(ContentBlock block) {
    if (!state.isStreaming) return;

    state = state.copyWith(contentBlocks: [...state.contentBlocks, block]);
  }

  /// Simulate streaming from a stream (for testing/development)
  void simulateStreaming(
    String fullText, {
    int chunkSize = 5,
    int delayMs = 50,
  }) {
    if (fullText.isEmpty) {
      finishStreaming();
      return;
    }

    final chunks = <String>[];
    for (var i = 0; i < fullText.length; i += chunkSize) {
      final end = (i + chunkSize < fullText.length)
          ? i + chunkSize
          : fullText.length;
      chunks.add(fullText.substring(i, end));
    }

    var currentIndex = 0;

    Timer.periodic(Duration(milliseconds: delayMs), (timer) {
      if (currentIndex < chunks.length) {
        appendTextChunk(chunks[currentIndex]);
        currentIndex++;
      } else {
        timer.cancel();
        finishStreaming();
      }
    });
  }

  /// Connect to a real stream (for production)
  void connectToStream(Stream<String> stream) {
    _streamSubscription?.cancel();

    _streamSubscription = stream.listen(
      (chunk) {
        appendTextChunk(chunk);
      },
      onError: (error) {
        setError('Stream error: $error');
      },
      onDone: () {
        finishStreaming();
      },
    );
  }

  /// Finish streaming and create the final message
  void finishStreaming() {
    if (!state.isStreaming) return;

    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Create final message from streaming content
    if (state.hasContent && state.sessionId != null) {
      final message = Message(
        id: _uuid.v4(),
        sessionId: state.sessionId!,
        role: MessageRole.assistant,
        content: state.contentBlocks,
        status: MessageStatus.delivered,
        createdAt: state.startedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(chatProvider.notifier).addAssistantMessage(message);
    }

    ref.read(chatProvider.notifier).stopReceiving();

    state = const StreamingState();
  }

  /// Cancel streaming
  void cancelStreaming() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    ref.read(chatProvider.notifier).stopReceiving();

    state = const StreamingState();
  }

  /// Set error state
  void setError(String error) {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    ref.read(chatProvider.notifier).stopReceiving();

    state = state.copyWith(isStreaming: false, error: error);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
