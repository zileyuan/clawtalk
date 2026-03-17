import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/task.dart';

/// Provider for the list of all tasks
final taskListProvider = StateNotifierProvider<TaskListNotifier, List<Task>>(
  (ref) => TaskListNotifier(),
);

/// Provider for tasks filtered by agent
final tasksByAgentProvider = Provider.family<List<Task>, String>((
  ref,
  agentId,
) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.agentId == agentId).toList();
});

/// Provider for active tasks (pending or running)
final activeTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.isInProgress).toList();
});

/// Provider for completed tasks
final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.isCompleted).toList();
});

/// Provider for the selected task ID
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the selected task
final selectedTaskProvider = Provider<Task?>((ref) {
  final taskId = ref.watch(selectedTaskIdProvider);
  if (taskId == null) return null;

  final tasks = ref.watch(taskListProvider);
  return tasks.firstWhere(
    (task) => task.id == taskId,
    orElse: () => throw Exception('Task not found: $taskId'),
  );
});

/// Provider for task statistics
final taskStatisticsProvider = Provider<TaskStatistics>((ref) {
  final tasks = ref.watch(taskListProvider);

  final total = tasks.length;
  final active = tasks.where((t) => t.isInProgress).length;
  final completed = tasks.where((t) => t.isCompleted).length;
  final failed = tasks.where((t) => t.hasFailed).length;
  final cancelled = tasks.where((t) => t.wasCancelled).length;

  return TaskStatistics(
    total: total,
    active: active,
    completed: completed,
    failed: failed,
    cancelled: cancelled,
  );
});

/// Statistics for tasks
class TaskStatistics {
  final int total;
  final int active;
  final int completed;
  final int failed;
  final int cancelled;

  const TaskStatistics({
    required this.total,
    required this.active,
    required this.completed,
    required this.failed,
    required this.cancelled,
  });

  double get completionRate => total > 0 ? completed / total : 0.0;
  double get failureRate => total > 0 ? failed / total : 0.0;
}

/// Notifier for managing the task list
class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier() : super([]);

  /// Create a new task
  Task createTask({required String sessionId, required String agentId}) {
    final task = Task(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      agentId: agentId,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
    );

    state = [...state, task];
    return task;
  }

  /// Start a task
  void startTask(String taskId) {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(status: TaskStatus.running);
      }
      return task;
    }).toList();
  }

  /// Update task progress
  void updateProgress(String taskId, double progress) {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(progress: progress.clamp(0.0, 1.0));
      }
      return task;
    }).toList();
  }

  /// Complete a task
  void completeTask(String taskId) {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          status: TaskStatus.completed,
          progress: 1.0,
          completedAt: DateTime.now(),
        );
      }
      return task;
    }).toList();
  }

  /// Mark a task as failed
  void failTask(String taskId) {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          status: TaskStatus.failed,
          completedAt: DateTime.now(),
        );
      }
      return task;
    }).toList();
  }

  /// Cancel a task
  void cancelTask(String taskId) {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          status: TaskStatus.cancelled,
          completedAt: DateTime.now(),
        );
      }
      return task;
    }).toList();
  }

  /// Remove a task
  void removeTask(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
  }

  /// Clear all completed tasks
  void clearCompleted() {
    state = state.where((task) => !task.isFinished).toList();
  }

  /// Clear all tasks
  void clearAll() {
    state = [];
  }

  /// Simulate task progress (for demo)
  void simulateProgress(String taskId) async {
    startTask(taskId);

    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      updateProgress(taskId, i / 10);
    }

    completeTask(taskId);
  }
}
