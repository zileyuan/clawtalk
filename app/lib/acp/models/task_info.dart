import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_info.freezed.dart';
part 'task_info.g.dart';

/// Task status enum
enum TaskStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('running')
  running,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// Task progress information
@freezed
class TaskProgress with _$TaskProgress {
  const factory TaskProgress({
    /// Current progress value (0-100)
    required int current,

    /// Total value (usually 100)
    @Default(100) int total,

    /// Progress message
    String? message,

    /// Progress percentage (0.0 - 1.0)
    @Default(0.0) double percentage,
  }) = _TaskProgress;

  factory TaskProgress.fromJson(Map<String, dynamic> json) =>
      _$TaskProgressFromJson(json);
}

/// Task information model
///
/// Represents an ongoing task within a session.
@freezed
class TaskInfo with _$TaskInfo {
  const factory TaskInfo({
    /// Unique task identifier
    required String id,

    /// Associated session ID
    required String sessionId,

    /// Task name/type
    String? name,

    /// Current task status
    @Default(TaskStatus.pending) TaskStatus status,

    /// Task progress
    TaskProgress? progress,

    /// Creation timestamp
    required DateTime createdAt,

    /// Start timestamp
    DateTime? startedAt,

    /// Completion timestamp
    DateTime? completedAt,

    /// Error message if failed
    String? error,

    /// Result data
    Map<String, dynamic>? result,

    /// Parent task ID (for subtasks)
    String? parentTaskId,

    /// Additional metadata
    Map<String, dynamic>? meta,
  }) = _TaskInfo;

  factory TaskInfo.fromJson(Map<String, dynamic> json) =>
      _$TaskInfoFromJson(json);
}

/// Extension for TaskInfo convenience methods
extension TaskInfoExtensions on TaskInfo {
  /// Check if task is pending
  bool get isPending => status == TaskStatus.pending;

  /// Check if task is running
  bool get isRunning => status == TaskStatus.running;

  /// Check if task is completed successfully
  bool get isCompleted => status == TaskStatus.completed;

  /// Check if task has failed
  bool get hasFailed => status == TaskStatus.failed || error != null;

  /// Check if task was cancelled
  bool get isCancelled => status == TaskStatus.cancelled;

  /// Check if task is finished (completed, failed, or cancelled)
  bool get isFinished =>
      status == TaskStatus.completed ||
      status == TaskStatus.failed ||
      status == TaskStatus.cancelled;

  /// Get progress percentage as a double (0.0 - 1.0)
  double get progressPercentage {
    if (progress == null) return 0.0;
    return progress!.percentage > 0
        ? progress!.percentage
        : progress!.total > 0
        ? progress!.current / progress!.total
        : 0.0;
  }

  /// Get progress percentage as an integer (0 - 100)
  int get progressPercent => (progressPercentage * 100).round();
}
