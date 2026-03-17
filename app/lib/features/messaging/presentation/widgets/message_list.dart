import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message.dart';
import '../providers/message_list_provider.dart';
import 'message_bubble.dart';

/// Scrollable message list with auto-scroll and pagination
class MessageList extends ConsumerStatefulWidget {
  /// Creates a message list
  const MessageList({
    super.key,
    required this.sessionId,
    this.onMessageTap,
    this.onMessageLongPress,
    this.padding,
  });

  /// The session ID to load messages for
  final String sessionId;

  /// Callback when a message is tapped
  final void Function(Message message)? onMessageTap;

  /// Callback when a message is long pressed
  final void Function(Message message)? onMessageLongPress;

  /// Padding around the list
  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(messageListProvider(widget.sessionId).notifier)
          .loadInitialMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasListeners) return;

    // Check if scrolled to bottom
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    _isScrolledToBottom = currentScroll >= maxScroll - 50;

    // Check if need to load more (pagination)
    if (currentScroll <= 100 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    _isLoadingMore = true;
    await ref
        .read(messageListProvider(widget.sessionId).notifier)
        .loadMoreMessages();
    _isLoadingMore = false;
  }

  void scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  void scrollToMessage(String messageId) {
    // This would require tracking message positions
    // Implementation depends on specific requirements
  }

  @override
  Widget build(BuildContext context) {
    final messageListState = ref.watch(messageListProvider(widget.sessionId));
    final messages = messageListState.sortedMessages;

    // Auto-scroll to bottom when new messages arrive if already at bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isScrolledToBottom && messages.isNotEmpty) {
        scrollToBottom(animated: true);
      }
    });

    if (messageListState.isInitialLoad && messageListState.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (messageListState.isEmpty) {
      return _buildEmptyState(context);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _onScroll();
        }
        return false;
      },
      child: CustomScrollView(
        controller: _scrollController,
        reverse: false,
        slivers: [
          // Loading indicator at top (for pagination)
          if (messageListState.isLoading && !messageListState.isInitialLoad)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),

          // Messages list
          SliverPadding(
            padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final message = messages[index];
                final isLastMessage = index == messages.length - 1;

                return MessageBubble(
                  message: message,
                  showTimestamp: true,
                  showStatus: isLastMessage,
                  onTap: () => widget.onMessageTap?.call(message),
                  onLongPress: () => widget.onMessageLongPress?.call(message),
                );
              }, childCount: messages.length),
            ),
          ),

          // Bottom spacer
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_text,
            size: 64,
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? CupertinoColors.label.darkColor
                  : CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to see messages here',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? CupertinoColors.secondaryLabel.darkColor
                  : CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension methods for MessageList
extension MessageListExtension on MessageList {
  /// Scroll to bottom helper that can be called from parent
  static void scrollToBottomOf(BuildContext context, {bool animated = true}) {
    final state = context.findAncestorStateOfType<_MessageListState>();
    state?.scrollToBottom(animated: animated);
  }
}
