import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/session.dart';
import '../providers/session_provider.dart';
import 'chat_screen.dart';

/// Session history list screen
class SessionListScreen extends ConsumerStatefulWidget {
  /// The connection ID for this session list
  final String? connectionId;

  /// Creates a session list screen
  const SessionListScreen({super.key, this.connectionId});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).loadSessions();
    });
  }

  void _navigateToChat(Session session) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => ChatScreen(session: session)),
    );
  }

  void _showSessionOptions(Session session) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Session Options'),
        actions: [
          if (session.status == SessionStatus.paused)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(sessionProvider.notifier).resumeSession(session.id);
              },
              child: const Text('Resume Session'),
            )
          else if (session.status == SessionStatus.active)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(sessionProvider.notifier).pauseSession(session.id);
              },
              child: const Text('Pause Session'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToChat(session);
            },
            child: const Text('Open Chat'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(session);
            },
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Session session) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(sessionProvider.notifier).deleteSession(session.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createNewSession() {
    // Show agent selection dialog
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Agent'),
        message: const Text('Choose an agent to start a new session'),
        actions: [
          // TODO: Load agents from provider
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _createSessionWithAgent('default-agent');
            },
            child: const Text('Default Agent'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _createSessionWithAgent(String agentId) async {
    final session = await ref
        .read(sessionProvider.notifier)
        .createSession(
          agentId: agentId,
          connectionId: widget.connectionId ?? 'default-connection',
        );

    if (session != null && mounted) {
      _navigateToChat(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsState = ref.watch(sessionProvider);
    final sessions = sessionsState.sortedSessions;
    final isLoading = sessionsState.isLoading;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Sessions'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _createNewSession,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Pull to refresh
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await ref.read(sessionProvider.notifier).refresh();
              },
            ),

            // Content
            if (isLoading && sessions.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (sessions.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(isDark))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final session = sessions[index];
                  return _buildSessionTile(session, isDark);
                }, childCount: sessions.length),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 80,
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Sessions',
            style: AppTextStyles.headline2.copyWith(
              color: isDark
                  ? CupertinoColors.label.darkColor
                  : CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation by tapping the + button',
            style: AppTextStyles.body.copyWith(
              color: isDark
                  ? CupertinoColors.secondaryLabel.darkColor
                  : CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: _createNewSession,
            child: const Text('New Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Session session, bool isDark) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final isActive = session.status == SessionStatus.active;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _navigateToChat(session),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(session.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Agent avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.gear_solid,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Agent ${session.agentId.substring(0, 8)}',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CupertinoColors.label.darkColor
                                  : CupertinoColors.label,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dateFormat.format(session.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? CupertinoColors.secondaryLabel.darkColor
                                : CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getStatusText(session.status),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? CupertinoColors.secondaryLabel.darkColor
                                  : CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // More options button
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                minSize: 36,
                onPressed: () => _showSessionOptions(session),
                child: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: isDark
                      ? CupertinoColors.secondaryLabel.darkColor
                      : CupertinoColors.secondaryLabel,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return AppColors.connected;
      case SessionStatus.paused:
        return AppColors.warning;
      case SessionStatus.ended:
        return AppColors.disconnected;
      case SessionStatus.error:
        return AppColors.error;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return 'Session active';
      case SessionStatus.paused:
        return 'Session paused';
      case SessionStatus.ended:
        return 'Session ended';
      case SessionStatus.error:
        return 'Session error';
    }
  }
}
