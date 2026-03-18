import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../client/acp_client.dart';
import '../client/message_queue.dart';
import '../exceptions/acp_exception.dart';
import '../protocol/acp_message.dart';

/// Message service provider
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

/// Service for handling ACP message sending and receiving
class MessageService {
  final Logger _logger;
  final MessageQueue<Map<String, dynamic>> _sendQueue;
  final Map<String, PendingRequest> _pendingRequests = {};

  final _messageController = StreamController<AcpMessageBase>.broadcast();
  final _errorController = StreamController<MessageError>.broadcast();

  StreamSubscription? _eventSubscription;

  MessageService({
    Logger? logger,
    MessageQueue<Map<String, dynamic>>? sendQueue,
  }) : _logger = logger ?? Logger(),
       _sendQueue = sendQueue ?? MessageQueue<Map<String, dynamic>>();

  /// Stream of incoming messages
  Stream<AcpMessageBase> get messages => _messageController.stream;

  /// Stream of message errors
  Stream<MessageError> get errors => _errorController.stream;

  /// Current queue status
  QueueStatus get queueStatus => _sendQueue.status;

  /// Queue status stream
  Stream<QueueStatus> get queueStatusStream => _sendQueue.onStatusChange;

  /// Initialize message service with an ACP client
  void initialize(AcpClient client) {
    _eventSubscription?.cancel();
    _eventSubscription = client.events.listen(
      _handleEvent,
      onError: (error) => _logger.e('Event stream error: $error'),
    );

    // Listen for messages ready to send
    _sendQueue.onMessageReady.listen((item) {
      _processQueueItem(client, item);
    });
  }

  /// Send a request and wait for response
  Future<T> sendRequest<T extends AcpResponse>(
    AcpClient client,
    AcpRequest request, {
    Duration? timeout,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    if (!client.isConnected) {
      throw AcpStateException.notConnected();
    }

    final completer = Completer<T>();
    final pending = PendingRequest(
      request: request,
      completer: completer,
      sentAt: DateTime.now(),
      timeout: timeout ?? const Duration(seconds: 30),
    );

    _pendingRequests[request.id] = pending;

    try {
      final response = await client.sendRequest<T>(request);

      // Validate response
      _validateResponse(response);

      // Notify listeners
      _messageController.add(response);

      return response;
    } catch (e) {
      _errorController.add(
        MessageError(
          messageId: request.id,
          error: e.toString(),
          type: MessageErrorType.sendFailed,
        ),
      );
      rethrow;
    } finally {
      _pendingRequests.remove(request.id);
    }
  }

  /// Queue a request for later sending
  String queueRequest(
    AcpRequest request, {
    MessagePriority priority = MessagePriority.normal,
    Duration? timeout,
  }) {
    final completer = Completer<AcpResponse>();
    final item = _sendQueue.enqueue(
      AcpMessageSerializer.serializeRequest(request),
      priority: priority,
      timeout: timeout,
      completer: completer,
    );

    _pendingRequests[request.id] = PendingRequest(
      request: request,
      completer: completer as Completer<dynamic>,
      sentAt: DateTime.now(),
      timeout: timeout ?? const Duration(seconds: 30),
    );

    return item.id;
  }

  /// Send a notification (fire and forget)
  Future<void> sendNotification(
    AcpClient client,
    AcpNotification notification, {
    MessagePriority priority = MessagePriority.normal,
  }) async {
    if (!client.isConnected) {
      throw AcpStateException.notConnected();
    }

    try {
      await client.sendNotification(notification);
      _messageController.add(notification);
    } catch (e) {
      _errorController.add(
        MessageError(
          messageId: notification.id,
          error: e.toString(),
          type: MessageErrorType.sendFailed,
        ),
      );
      rethrow;
    }
  }

  /// Send raw JSON data
  Future<void> sendRaw(AcpClient client, Map<String, dynamic> data) async {
    if (!client.isConnected) {
      throw AcpStateException.notConnected();
    }

    await client.sendRaw(data);
  }

  /// Get pending request by ID
  PendingRequest? getPendingRequest(String id) => _pendingRequests[id];

  /// Cancel a pending request
  bool cancelRequest(String id) {
    final pending = _pendingRequests.remove(id);
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.completeError(
        AcpRequestException('Request cancelled', requestId: id),
      );
      return true;
    }
    return false;
  }

  /// Clear all pending requests
  void clearPending() {
    for (final pending in _pendingRequests.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(
          AcpRequestException(
            'Requests cleared',
            requestId: pending.request.id,
          ),
        );
      }
    }
    _pendingRequests.clear();
    _sendQueue.clear();
  }

  /// Remove expired requests
  void removeExpired() {
    _sendQueue.removeExpired();

    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final entry in _pendingRequests.entries) {
      if (now.difference(entry.value.sentAt) > entry.value.timeout) {
        expiredIds.add(entry.key);
        if (!entry.value.completer.isCompleted) {
          entry.value.completer.completeError(
            AcpTimeoutException('Request expired'),
          );
        }
      }
    }

    for (final id in expiredIds) {
      _pendingRequests.remove(id);
    }
  }

  /// Process a queue item
  void _processQueueItem(
    AcpClient client,
    QueueItem<Map<String, dynamic>> item,
  ) {
    if (!client.isConnected) {
      item.markFailed('Client not connected');
      return;
    }

    client
        .sendRaw(item.message)
        .then((_) {
          item.markSent();
        })
        .catchError((error) {
          item.markFailed(error.toString());
          _errorController.add(
            MessageError(
              messageId: item.id,
              error: error.toString(),
              type: MessageErrorType.sendFailed,
            ),
          );
        });
  }

  /// Handle incoming event
  void _handleEvent(AcpEvent event) {
    _messageController.add(event);
  }

  /// Validate response
  void _validateResponse(AcpResponse response) {
    if (!response.success && response.error != null) {
      throw AcpRequestException(
        response.error!,
        code: response.errorCode,
        requestId: response.requestId,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    clearPending();
    _messageController.close();
    _errorController.close();
    _sendQueue.dispose();
  }
}

/// Pending request tracking
class PendingRequest {
  final AcpRequest request;
  final Completer<dynamic> completer;
  final DateTime sentAt;
  final Duration timeout;
  int retryCount;

  PendingRequest({
    required this.request,
    required this.completer,
    required this.sentAt,
    required this.timeout,
    this.retryCount = 0,
  });

  bool get isExpired => DateTime.now().difference(sentAt) > timeout;
}

/// Message error information
class MessageError {
  final String messageId;
  final String error;
  final MessageErrorType type;
  final DateTime timestamp;

  MessageError({
    required this.messageId,
    required this.error,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Message error types
enum MessageErrorType {
  sendFailed,
  timeout,
  validationFailed,
  connectionLost,
  protocolError,
}
