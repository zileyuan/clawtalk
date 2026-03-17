import 'dart:async';
import 'dart:collection';

import 'package:uuid/uuid.dart';

/// Message status for tracking delivery
enum MessageStatus {
  /// Message is pending to be sent
  pending,

  /// Message has been sent, waiting for acknowledgment
  sent,

  /// Message acknowledged by server
  acknowledged,

  /// Message failed to send
  failed,

  /// Message timed out waiting for acknowledgment
  timeout,
}

/// Priority levels for message queue
enum MessagePriority {
  /// High priority - sent first
  high,

  /// Normal priority - default
  normal,

  /// Low priority - sent last
  low,
}

/// Queue item representing a message in the queue
class QueueItem<T> {
  final String id;
  final T message;
  final MessagePriority priority;
  final DateTime createdAt;
  final int retryCount;
  final Duration? timeout;
  final Completer<dynamic>? completer;

  MessageStatus status;
  DateTime? sentAt;
  DateTime? acknowledgedAt;
  String? errorMessage;

  QueueItem({
    String? id,
    required this.message,
    this.priority = MessagePriority.normal,
    this.retryCount = 0,
    this.timeout,
    this.completer,
    this.status = MessageStatus.pending,
    DateTime? createdAt,
    this.sentAt,
    this.acknowledgedAt,
    this.errorMessage,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Check if message has expired
  bool get isExpired {
    if (timeout == null) return false;
    return DateTime.now().difference(createdAt) > timeout!;
  }

  /// Check if message has exceeded max retries
  bool get hasExceededRetries => retryCount >= maxRetries;

  /// Default max retries
  static const int maxRetries = 3;

  /// Create a copy with incremented retry count
  QueueItem<T> withRetry() => QueueItem<T>(
    id: id,
    message: message,
    priority: priority,
    retryCount: retryCount + 1,
    timeout: timeout,
    completer: completer,
    status: MessageStatus.pending,
    createdAt: createdAt,
  );

  /// Mark as sent
  void markSent() {
    status = MessageStatus.sent;
    sentAt = DateTime.now();
  }

  /// Mark as acknowledged
  void markAcknowledged() {
    status = MessageStatus.acknowledged;
    acknowledgedAt = DateTime.now();
  }

  /// Mark as failed
  void markFailed(String error) {
    status = MessageStatus.failed;
    errorMessage = error;
  }

  /// Mark as timeout
  void markTimeout() {
    status = MessageStatus.timeout;
    errorMessage = 'Message timed out';
  }

  /// Calculate latency
  Duration? get latency {
    if (sentAt == null || acknowledgedAt == null) return null;
    return acknowledgedAt!.difference(sentAt!);
  }
}

/// Message queue for reliable message delivery
class MessageQueue<T> {
  final int maxSize;
  final Duration defaultTimeout;
  final int maxRetries;

  final Queue<QueueItem<T>> _queue = Queue<QueueItem<T>>();
  final Map<String, QueueItem<T>> _pending = {};
  final Map<String, QueueItem<T>> _completed = {};

  final _queueController = StreamController<QueueItem<T>>.broadcast();
  final _statusController = StreamController<QueueStatus>.broadcast();

  Stream<QueueItem<T>> get onMessageReady => _queueController.stream;
  Stream<QueueStatus> get onStatusChange => _statusController.stream;

  MessageQueue({
    this.maxSize = 1000,
    this.defaultTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  /// Get current queue status
  QueueStatus get status => QueueStatus(
    queueLength: _queue.length,
    pendingCount: _pending.length,
    completedCount: _completed.length,
  );

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty && _pending.isEmpty;

  /// Check if queue is full
  bool get isFull => _queue.length >= maxSize;

  /// Get next message to send (sorted by priority)
  QueueItem<T>? peek() {
    if (_queue.isEmpty) return null;

    // Sort by priority (high first)
    final sorted = _queue.toList()
      ..sort((a, b) {
        final priorityOrder = {
          MessagePriority.high: 0,
          MessagePriority.normal: 1,
          MessagePriority.low: 2,
        };
        return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      });

    return sorted.first;
  }

  /// Enqueue a message
  QueueItem<T> enqueue(
    T message, {
    MessagePriority priority = MessagePriority.normal,
    Duration? timeout,
    Completer<dynamic>? completer,
  }) {
    if (isFull) {
      throw StateError('Message queue is full');
    }

    final item = QueueItem<T>(
      message: message,
      priority: priority,
      timeout: timeout ?? defaultTimeout,
      completer: completer,
    );

    _queue.add(item);
    _queueController.add(item);
    _notifyStatusChange();

    return item;
  }

  /// Dequeue the next message for sending
  QueueItem<T>? dequeue() {
    final item = peek();
    if (item == null) return null;

    _queue.remove(item);
    _pending[item.id] = item;
    item.markSent();
    _notifyStatusChange();

    return item;
  }

  /// Acknowledge a message by ID
  bool acknowledge(String id, {dynamic response}) {
    final item = _pending.remove(id);
    if (item == null) return false;

    item.markAcknowledged();
    _completed[id] = item;

    // Complete the completer if exists
    if (item.completer != null && !item.completer!.isCompleted) {
      item.completer!.complete(response);
    }

    _notifyStatusChange();

    // Clean up old completed items
    _cleanupCompleted();

    return true;
  }

  /// Mark a message as failed
  void fail(String id, String error) {
    final item = _pending.remove(id);
    if (item == null) return;

    item.markFailed(error);

    // Complete the completer with error
    if (item.completer != null && !item.completer!.isCompleted) {
      item.completer!.completeError(Exception(error));
    }

    _notifyStatusChange();
  }

  /// Retry a failed message
  void retry(String id) {
    final item = _pending[id] ?? _completed[id];
    if (item == null) return;

    if (item.retryCount < maxRetries && !item.isExpired) {
      final retryItem = item.withRetry();
      _pending.remove(id);
      _completed.remove(id);
      _queue.add(retryItem);
      _queueController.add(retryItem);
    }

    _notifyStatusChange();
  }

  /// Remove expired messages
  void removeExpired() {
    final expiredIds = <String>[];

    for (final item in [..._queue, ..._pending.values]) {
      if (item.isExpired) {
        expiredIds.add(item.id);
        item.markTimeout();

        if (item.completer != null && !item.completer!.isCompleted) {
          item.completer!.completeError(TimeoutException('Message expired'));
        }
      }
    }

    _queue.removeWhere((item) => expiredIds.contains(item.id));
    for (final id in expiredIds) {
      _pending.remove(id);
    }

    if (expiredIds.isNotEmpty) {
      _notifyStatusChange();
    }
  }

  /// Clear the queue
  void clear() {
    for (final item in [..._queue, ..._pending.values]) {
      if (item.completer != null && !item.completer!.isCompleted) {
        item.completer!.completeError(StateError('Queue cleared'));
      }
    }

    _queue.clear();
    _pending.clear();
    _completed.clear();
    _notifyStatusChange();
  }

  /// Get item by ID
  QueueItem<T>? getItem(String id) {
    // Check queue first
    for (final item in _queue) {
      if (item.id == id) return item;
    }
    // Then check pending and completed
    return _pending[id] ?? _completed[id];
  }

  /// Get all pending message IDs
  List<String> get pendingIds => _pending.keys.toList();

  /// Get all queued message IDs
  List<String> get queuedIds => _queue.map((item) => item.id).toList();

  void _cleanupCompleted() {
    // Keep only last 100 completed items
    if (_completed.length > 100) {
      final keysToRemove = _completed.keys
          .take(_completed.length - 100)
          .toList();
      for (final key in keysToRemove) {
        _completed.remove(key);
      }
    }
  }

  void _notifyStatusChange() {
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    clear();
    _queueController.close();
    _statusController.close();
  }
}

/// Queue status information
class QueueStatus {
  final int queueLength;
  final int pendingCount;
  final int completedCount;

  const QueueStatus({
    required this.queueLength,
    required this.pendingCount,
    required this.completedCount,
  });

  int get totalMessages => queueLength + pendingCount;

  @override
  String toString() =>
      'QueueStatus(queue: $queueLength, pending: $pendingCount, completed: $completedCount)';
}
