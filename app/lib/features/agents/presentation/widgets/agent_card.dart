import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/agent.dart';

/// Card widget displaying agent information
class AgentCard extends StatelessWidget {
  final Agent agent;
  final VoidCallback? onTap;

  const AgentCard({super.key, required this.agent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            // Agent icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getStatusColor().withAlpha(26),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                CupertinoIcons.person_alt_circle,
                size: 32,
                color: _getStatusColor(),
              ),
            ),
            const SizedBox(width: 16),
            // Agent info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          agent.name,
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusIndicator(),
                    ],
                  ),
                  if (agent.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      agent.description!,
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 14,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.star,
                        size: 14,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${agent.capabilities.length} capabilities',
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(
                              color: CupertinoColors.tertiaryLabel,
                              fontSize: 13,
                            ),
                      ),
                      if (agent.lastActive != null) ...[
                        const Spacer(),
                        Text(
                          _formatLastActive(agent.lastActive!),
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
                                color: CupertinoColors.tertiaryLabel,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    String text;

    switch (agent.status) {
      case AgentStatus.available:
        color = AppColors.success;
        text = 'Available';
      case AgentStatus.busy:
        color = AppColors.warning;
        text = 'Busy';
      case AgentStatus.offline:
        color = AppColors.disconnected;
        text = 'Offline';
      case AgentStatus.error:
        color = AppColors.error;
        text = 'Error';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (agent.status) {
      case AgentStatus.available:
        return AppColors.success;
      case AgentStatus.busy:
        return AppColors.warning;
      case AgentStatus.offline:
        return AppColors.disconnected;
      case AgentStatus.error:
        return AppColors.error;
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final difference = DateTime.now().difference(lastActive);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
