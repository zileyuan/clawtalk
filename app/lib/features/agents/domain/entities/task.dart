/// Enum representing the status of a task.
enum TaskStatus { pending, running, completed, failed, cancelled }

/// A task entity representing a task being executed by an agent.
class Task {
  final String id;
  final String sessionId;
  final String agentId;
  final TaskStatus status;
  final double? progress;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.sessionId,
    required this.agentId,
    this.status = TaskStatus.pending,
    this.progress,
    required this.createdAt,
    this.completedAt,
  });

  /// Returns true if the task is still in progress.
  bool get isInProgress =>
      status == TaskStatus.pending || status == TaskStatus.running;

  /// Returns true if the task has completed successfully.
  bool get isCompleted => status == TaskStatus.completed;

  /// Returns true if the task has failed.
  bool get hasFailed => status == TaskStatus.failed;

  /// Returns true if the task was cancelled.
  bool get wasCancelled => status == TaskStatus.cancelled;

  /// Returns true if the task is finished (completed, failed, or cancelled).
  bool get isFinished =>
      status == TaskStatus.completed ||
      status == TaskStatus.failed ||
      status == TaskStatus.cancelled;

  /// Returns the progress as a percentage (0-100).
  int get progressPercentage {
    if (progress == null) return 0;
    return (progress! * 100).clamp(0, 100).toInt();
  }

  /// Returns the duration of the task if completed, null otherwise.
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  Task copyWith({
    String? id,
    String? sessionId,
    String? agentId,
    TaskStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      agentId: agentId ?? this.agentId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.agentId == agentId &&
        other.status == status &&
        other.progress == progress &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sessionId,
      agentId,
      status,
      progress,
      createdAt,
      completedAt,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, sessionId: $sessionId, agentId: $agentId, '
        'status: $status, progress: $progress, createdAt: $createdAt)';
  }
}
