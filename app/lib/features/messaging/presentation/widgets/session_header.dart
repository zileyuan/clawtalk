import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/session.dart';
import '../providers/session_provider.dart';

/// Header showing session and agent info
class SessionHeader extends ConsumerWidget {
  /// Creates a session header
  const SessionHeader({
    super.key,
    this.session,
    this.agentName,
    this.agentAvatar,
    this.onBackPressed,
    this.onMenuPressed,
    this.showConnectionStatus = true,
  });

  /// The current session (optional, will be read from provider if null)
  final Session? session;

  /// Name of the agent
  final String? agentName;

  /// Avatar widget for the agent
  final Widget? agentAvatar;

  /// Callback when back button is pressed
  final VoidCallback? onBackPressed;

  /// Callback when menu button is pressed
  final VoidCallback? onMenuPressed;

  /// Whether to show connection status indicator
  final bool showConnectionStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSession = session ?? ref.watch(activeSessionProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.secondarySystemBackground.darkColor
            : CupertinoColors.secondarySystemBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Back button
              if (onBackPressed != null)
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minSize: 44,
                  onPressed: onBackPressed,
                  child: Icon(
                    CupertinoIcons.back,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),

              // Agent avatar
              _buildAvatar(currentSession, context),
              const SizedBox(width: 12),

              // Agent name and status
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentName ?? _getAgentName(currentSession),
                      style: AppTextStyles.headline3.copyWith(
                        color: isDark
                            ? CupertinoColors.label.darkColor
                            : CupertinoColors.label,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showConnectionStatus)
                      _buildStatusText(currentSession, isDark),
                  ],
                ),
              ),

              // Menu/actions button
              if (onMenuPressed != null)
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minSize: 44,
                  onPressed: onMenuPressed,
                  child: Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: isDark
                        ? CupertinoColors.label.darkColor
                        : CupertinoColors.label,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Session? session, BuildContext context) {
    if (agentAvatar != null) return agentAvatar!;

    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemGrey6,
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.gear_solid,
          color: CupertinoColors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStatusText(Session? session, bool isDark) {
    String statusText;
    Color statusColor;

    if (session == null) {
      statusText = 'Not connected';
      statusColor = AppColors.disconnected;
    } else {
      switch (session.status) {
        case SessionStatus.active:
          // Show model name if available
          statusText = session.model.isNotEmpty ? session.model : 'Online';
          statusColor = AppColors.connected;
        case SessionStatus.paused:
          statusText = 'Paused';
          statusColor = AppColors.warning;
        case SessionStatus.ended:
          statusText = 'Session ended';
          statusColor = AppColors.disconnected;
        case SessionStatus.error:
          statusText = 'Error';
          statusColor = AppColors.error;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: AppTextStyles.caption.copyWith(
            color: statusColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getAgentName(Session? session) {
    if (session == null) return 'Select Agent';
    // Display key if available, otherwise agentId
    if (session.key.isNotEmpty) {
      return session.key.length > 30
          ? '${session.key.substring(0, 30)}...'
          : session.key;
    }
    // Fallback to agentId (with length check)
    if (session.agentId.isEmpty) return 'Agent';
    return session.agentId.length > 8
        ? 'Agent ${session.agentId.substring(0, 8)}'
        : 'Agent ${session.agentId}';
  }
}

/// Minimal header for compact use
class CompactSessionHeader extends StatelessWidget {
  /// Creates a compact session header
  const CompactSessionHeader({
    super.key,
    this.title = 'Chat',
    this.subtitle,
    this.onBackPressed,
    this.onClosePressed,
  });

  /// Header title
  final String title;

  /// Header subtitle
  final String? subtitle;

  /// Callback when back button is pressed
  final VoidCallback? onBackPressed;

  /// Callback when close button is pressed
  final VoidCallback? onClosePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.secondarySystemBackground.darkColor
            : CupertinoColors.secondarySystemBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onBackPressed != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 36,
              onPressed: onBackPressed,
              child: Icon(CupertinoIcons.back, color: AppColors.primary),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: onBackPressed != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.headline3),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (onClosePressed != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 36,
              onPressed: onClosePressed,
              child: Icon(
                CupertinoIcons.xmark,
                color: isDark
                    ? CupertinoColors.label.darkColor
                    : CupertinoColors.label,
              ),
            ),
        ],
      ),
    );
  }
}
