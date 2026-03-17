import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../providers/task_provider.dart';

/// Progress indicator for running tasks
class TaskProgressIndicator extends ConsumerWidget {
  final String? taskId;
  final bool showPercentage;
  final double height;

  const TaskProgressIndicator({
    super.key,
    this.taskId,
    this.showPercentage = true,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = taskId != null
        ? ref.watch(selectedTaskProvider)
        : ref.watch(activeTasksProvider).firstOrNull;

    if (task == null) {
      return _buildEmptyState();
    }

    final progress = task.progress ?? 0.0;
    final percentage = task.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Task Progress',
              style: CupertinoTheme.of(
                context,
              ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w500),
            ),
            if (showPercentage)
              Text(
                '$percentage%',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: progress * 200, // Max width
                  height: height,
                  decoration: BoxDecoration(
                    color: _getProgressColor(progress),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _getStatusIcon(task.status),
              size: 16,
              color: _getStatusColor(task.status),
            ),
            const SizedBox(width: 6),
            Text(
              _getStatusText(task.status),
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            if (task.isInProgress && task.progress != null) ...[
              const Spacer(),
              CupertinoActivityIndicator(radius: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'No Active Tasks',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return AppColors.success;
    } else if (progress >= 0.5) {
      return AppColors.primary;
    } else {
      return AppColors.warning;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return CupertinoIcons.clock;
      case TaskStatus.running:
        return CupertinoIcons.arrow_2_circlepath;
      case TaskStatus.completed:
        return CupertinoIcons.checkmark_circle_fill;
      case TaskStatus.failed:
        return CupertinoIcons.exclamationmark_circle_fill;
      case TaskStatus.cancelled:
        return CupertinoIcons.xmark_circle_fill;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return CupertinoColors.systemGrey;
      case TaskStatus.running:
        return AppColors.primary;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.failed:
        return AppColors.error;
      case TaskStatus.cancelled:
        return CupertinoColors.systemGrey;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.running:
        return 'Running';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Mini progress indicator for use in lists
class TaskProgressIndicatorMini extends ConsumerWidget {
  final String taskId;

  const TaskProgressIndicatorMini({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(selectedTaskProvider);

    if (task == null || task.id != taskId) {
      return const SizedBox.shrink();
    }

    final progress = task.progress ?? 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CupertinoColors.systemGrey5,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${task.progressPercentage}%',
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}
