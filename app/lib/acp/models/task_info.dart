/// Task status enum
enum TaskStatus {
  pending,
  running,
  completed,
  failed,
  cancelled;

  String toJson() => name;

  static TaskStatus fromJson(String value) => TaskStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TaskStatus.pending,
  );
}

/// Task progress information
class TaskProgress {
  /// Current progress value (0-100)
  final int current;

  /// Total value (usually 100)
  final int total;

  /// Progress message
  final String? message;

  /// Progress percentage (0.0 - 1.0)
  final double percentage;

  const TaskProgress({
    required this.current,
    this.total = 100,
    this.message,
    this.percentage = 0.0,
  });

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    return TaskProgress(
      current: json['current'] as int,
      total: json['total'] as int? ?? 100,
      message: json['message'] as String?,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'current': current};
    if (total != 100) json['total'] = total;
    if (message != null) json['message'] = message;
    if (percentage != 0.0) json['percentage'] = percentage;
    return json;
  }

  TaskProgress copyWith({
    int? current,
    int? total,
    String? message,
    double? percentage,
  }) {
    return TaskProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      message: message ?? this.message,
      percentage: percentage ?? this.percentage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskProgress &&
        other.current == current &&
        other.total == total &&
        other.message == message &&
        other.percentage == percentage;
  }

  @override
  int get hashCode => Object.hash(current, total, message, percentage);

  @override
  String toString() =>
      'TaskProgress(current: $current, total: $total, message: $message, percentage: $percentage)';
}

/// Task information model
///
/// Represents an ongoing task within a session.
class TaskInfo {
  /// Unique task identifier
  final String id;

  /// Associated session ID
  final String sessionId;

  /// Task name/type
  final String? name;

  /// Current task status
  final TaskStatus status;

  /// Task progress
  final TaskProgress? progress;

  /// Creation timestamp
  final DateTime createdAt;

  /// Start timestamp
  final DateTime? startedAt;

  /// Completion timestamp
  final DateTime? completedAt;

  /// Error message if failed
  final String? error;

  /// Result data
  final Map<String, dynamic>? result;

  /// Parent task ID (for subtasks)
  final String? parentTaskId;

  /// Additional metadata
  final Map<String, dynamic>? meta;

  const TaskInfo({
    required this.id,
    required this.sessionId,
    this.name,
    this.status = TaskStatus.pending,
    this.progress,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.error,
    this.result,
    this.parentTaskId,
    this.meta,
  });

  factory TaskInfo.fromJson(Map<String, dynamic> json) {
    return TaskInfo(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      name: json['name'] as String?,
      status: json['status'] != null
          ? TaskStatus.fromJson(json['status'] as String)
          : TaskStatus.pending,
      progress: json['progress'] != null
          ? TaskProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      error: json['error'] as String?,
      result: json['result'] as Map<String, dynamic>?,
      parentTaskId: json['parentTaskId'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'sessionId': sessionId,
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
    if (name != null) json['name'] = name;
    if (progress != null) json['progress'] = progress!.toJson();
    if (startedAt != null) json['startedAt'] = startedAt!.toIso8601String();
    if (completedAt != null)
      json['completedAt'] = completedAt!.toIso8601String();
    if (error != null) json['error'] = error;
    if (result != null) json['result'] = result;
    if (parentTaskId != null) json['parentTaskId'] = parentTaskId;
    if (meta != null) json['meta'] = meta;
    return json;
  }

  TaskInfo copyWith({
    String? id,
    String? sessionId,
    String? name,
    TaskStatus? status,
    TaskProgress? progress,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
    Map<String, dynamic>? result,
    String? parentTaskId,
    Map<String, dynamic>? meta,
  }) {
    return TaskInfo(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
      result: result ?? this.result,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      meta: meta ?? this.meta,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskInfo &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.name == name &&
        other.status == status &&
        other.progress == progress &&
        other.createdAt == createdAt &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.error == error &&
        other.result == result &&
        other.parentTaskId == parentTaskId &&
        other.meta == meta;
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    name,
    status,
    progress,
    createdAt,
    startedAt,
    completedAt,
    error,
    result,
    parentTaskId,
    meta,
  );

  @override
  String toString() =>
      'TaskInfo(id: $id, sessionId: $sessionId, name: $name, status: $status, '
      'progress: $progress, createdAt: $createdAt, startedAt: $startedAt, '
      'completedAt: $completedAt, error: $error, result: $result, '
      'parentTaskId: $parentTaskId, meta: $meta)';
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
