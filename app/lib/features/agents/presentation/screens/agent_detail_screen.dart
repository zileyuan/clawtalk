import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/agent.dart';
import '../providers/agent_detail_provider.dart';
import '../providers/agent_list_provider.dart';
import '../widgets/agent_capability_chip.dart';
import '../widgets/task_progress_indicator.dart';

/// Screen showing agent details and capabilities
class AgentDetailScreen extends ConsumerStatefulWidget {
  final String agentId;

  const AgentDetailScreen({super.key, required this.agentId});

  @override
  ConsumerState<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends ConsumerState<AgentDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load agent details when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agentDetailStateProvider.notifier).loadAgent(widget.agentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentDetailStateProvider);
    final agent = agentState.agent;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(agent?.name ?? 'Agent Details'),
        trailing: agent != null ? _buildStatusIndicator(agent.status) : null,
      ),
      child: SafeArea(
        child: agentState.isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : agentState.error != null
            ? _buildErrorState(agentState.error!)
            : agent == null
            ? _buildEmptyState()
            : _buildAgentDetails(agent),
      ),
    );
  }

  Widget _buildStatusIndicator(AgentStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case AgentStatus.available:
        color = AppColors.success;
        icon = CupertinoIcons.checkmark_circle_fill;
      case AgentStatus.busy:
        color = AppColors.warning;
        icon = CupertinoIcons.clock_fill;
      case AgentStatus.offline:
        color = AppColors.disconnected;
        icon = CupertinoIcons.xmark_circle_fill;
      case AgentStatus.error:
        color = AppColors.error;
        icon = CupertinoIcons.exclamationmark_circle_fill;
    }

    return Icon(icon, color: color, size: 20);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading agent',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            child: const Text('Retry'),
            onPressed: () {
              ref
                  .read(agentDetailStateProvider.notifier)
                  .loadAgent(widget.agentId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Agent not found'));
  }

  Widget _buildAgentDetails(Agent agent) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.person_alt_circle,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent.name,
                            style: CupertinoTheme.of(
                              context,
                            ).textTheme.navLargeTitleTextStyle,
                          ),
                          if (agent.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              agent.description!,
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Status section
                _buildSectionTitle('Status'),
                const SizedBox(height: 8),
                _buildStatusRow('Current Status', _getStatusText(agent.status)),
                if (agent.lastActive != null)
                  _buildStatusRow(
                    'Last Active',
                    _formatLastActive(agent.lastActive!),
                  ),

                const SizedBox(height: 24),

                // Capabilities section
                _buildSectionTitle('Capabilities'),
                const SizedBox(height: 8),
                if (agent.capabilities.isEmpty)
                  Text(
                    'No capabilities listed',
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(color: CupertinoColors.secondaryLabel),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: agent.capabilities
                        .map((cap) => AgentCapabilityChip(capability: cap))
                        .toList(),
                  ),

                const SizedBox(height: 24),

                // Actions
                _buildSectionTitle('Actions'),
                const SizedBox(height: 8),
                if (agent.isAvailable)
                  CupertinoButton.filled(
                    child: const Text('Start Task'),
                    onPressed: () {
                      _showStartTaskDialog(context, agent);
                    },
                  )
                else
                  CupertinoButton(
                    color: CupertinoColors.systemGrey,
                    child: const Text('Agent Unavailable'),
                    onPressed: null,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: CupertinoTheme.of(
        context,
      ).textTheme.navTitleTextStyle.copyWith(fontSize: 20),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AgentStatus status) {
    switch (status) {
      case AgentStatus.available:
        return 'Available';
      case AgentStatus.busy:
        return 'Busy';
      case AgentStatus.offline:
        return 'Offline';
      case AgentStatus.error:
        return 'Error';
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

  void _showStartTaskDialog(BuildContext context, Agent agent) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Start Task with ${agent.name}'),
        message: const Text('Choose a task type'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showTaskProgress(context);
            },
            child: const Text('Quick Task'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to task configuration
            },
            child: const Text('Custom Task'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showTaskProgress(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Task Started'),
        content: const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: TaskProgressIndicator(),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Dismiss'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
