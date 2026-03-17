import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/session.dart';
import '../providers/chat_provider.dart';
import '../providers/session_provider.dart';
import '../providers/streaming_provider.dart';
import '../widgets/message_input_area.dart';
import '../widgets/message_list.dart';
import '../widgets/session_header.dart';
import '../widgets/streaming_text.dart';
import '../widgets/typing_indicator.dart';

/// Main chat screen with message list, input area, and session header
class ChatScreen extends ConsumerStatefulWidget {
  /// Creates a chat screen
  const ChatScreen({super.key, this.sessionId, this.session})
      : assert(
          sessionId != null || session != null,
          'Either sessionId or session must be provided',
        );

  /// The session ID to load
  final String? sessionId;

  /// The session object (optional, will be loaded from provider if null)
  final Session? session;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the session in the chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  void _initializeSession() {
    final session = widget.session;
    final sessionId = widget.sessionId;

    if (session != null) {
      ref.read(chatProvider.notifier).initializeSession(session);
      ref.read(sessionProvider.notifier).setActiveSession(session);
    } else if (sessionId != null) {
      // Try to find the session in the list
      final sessions = ref.read(sessionsListProvider);
      final foundSession = sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw Exception('Session not found: $sessionId'),
      );
      ref.read(chatProvider.notifier).initializeSession(foundSession);
      ref.read(sessionProvider.notifier).setActiveSession(foundSession);
    }
  }

  void _handleSend(String text) {
    // The message is already sent via the provider in MessageInputArea
    // This callback can be used for additional handling
  }

  void _handleImagePick() {
    // TODO: Implement image picker
    _showNotImplemented('Image picker');
  }

  void _handleVoiceRecord() {
    // TODO: Implement voice recorder
    _showNotImplemented('Voice recorder');
  }

  void _showNotImplemented(String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _handleMenuPressed() {
    // Show session options menu
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Session Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Clear chat history
            },
            child: const Text('Clear History'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Export chat
            },
            child: const Text('Export Chat'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showEndSessionDialog();
            },
            isDestructiveAction: true,
            child: const Text('End Session'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showEndSessionDialog() {
    final currentSession = ref.read(currentSessionProvider);
    if (currentSession == null) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(sessionProvider.notifier).endSession(currentSession.id);
              Navigator.of(context).pop(); // Go back to session list
            },
            child: const Text('End'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = ref.watch(currentSessionProvider);
    final isReceiving = ref.watch(isReceivingProvider);
    final streamingText = ref.watch(streamingTextProvider);

    if (currentSession == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Chat')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Column(
        children: [
          // Session header
          SessionHeader(
            session: currentSession,
            onBackPressed: () => Navigator.of(context).pop(),
            onMenuPressed: _handleMenuPressed,
          ),

          // Message list
          Expanded(
            child: MessageList(
              sessionId: currentSession.id,
              onMessageTap: (message) {
                // Handle message tap (e.g., show details)
              },
              onMessageLongPress: (message) {
                // Handle message long press (e.g., show context menu)
              },
            ),
          ),

          // Streaming response indicator
          if (isReceiving) _buildStreamingIndicator(streamingText),

          // Typing indicator
          if (isReceiving && streamingText.isEmpty) _buildTypingIndicator(),

          // Input area
          MessageInputArea(
            onSend: _handleSend,
            onImagePick: _handleImagePick,
            onVoiceRecord: _handleVoiceRecord,
            enabled: currentSession.status == SessionStatus.active,
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingIndicator(String text) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.assistantMessage,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.gear_solid,
              color: CupertinoColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: StreamingTextDisplay(text: text, showCursor: true)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.assistantMessage,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.gear_solid,
              color: CupertinoColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const TypingIndicator(),
        ],
      ),
    );
  }
}
