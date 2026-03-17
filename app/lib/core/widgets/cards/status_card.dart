import 'package:flutter/cupertino.dart';

import '../../../features/connection/domain/entities/connection_status.dart';
import '../../themes/app_colors.dart';
import '../indicators/status_indicator.dart';

/// Card widget for displaying connection status information.
///
/// Used in connection lists to show status, details, and quick actions.
class StatusCard extends StatelessWidget {
  /// Creates a status card.
  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showStatusIndicator = true,
    this.isSelected = false,
  });

  /// The title of the connection.
  final String title;

  /// Current connection status.
  final ConnectionStatus status;

  /// Optional subtitle (e.g., host:port).
  final String? subtitle;

  /// Optional trailing widget (e.g., action button).
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Internal padding.
  final EdgeInsetsGeometry padding;

  /// External margin.
  final EdgeInsetsGeometry margin;

  /// Whether to show the status indicator dot.
  final bool showStatusIndicator;

  /// Whether this card is selected.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                ? CupertinoColors.systemGrey.withOpacity(0.2)
                : CupertinoColors.systemGrey4,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onTap,
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  if (showStatusIndicator) ...[
                    ConnectionStatusIndicator(status: status),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? CupertinoColors.systemGrey.darkColor
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                fontSize: 13,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.connected;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return AppColors.connecting;
      case ConnectionStatus.disconnected:
        return AppColors.disconnected;
      case ConnectionStatus.error:
        return AppColors.errorStatus;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnecting:
        return 'Disconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }
}

/// A compact version of the status card for list views.
class StatusCardCompact extends StatelessWidget {
  /// Creates a compact status card.
  const StatusCardCompact({
    super.key,
    required this.title,
    required this.status,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  /// The title of the connection.
  final String title;

  /// Current connection status.
  final ConnectionStatus status;

  /// Optional subtitle.
  final String? subtitle;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Whether this card is selected.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey.withOpacity(0.2)
                : CupertinoColors.systemGrey4,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: onTap,
        child: Row(
          children: [
            ConnectionStatusIndicator(status: status, size: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: isDark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }
}
