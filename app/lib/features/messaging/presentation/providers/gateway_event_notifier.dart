import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:clawtalk/core/providers/connection_provider.dart';
import 'package:clawtalk/features/messaging/presentation/providers/chat_provider.dart';
import 'package:clawtalk/features/messaging/presentation/providers/streaming_provider.dart';
import 'package:clawtalk/gateway/protocol/gateway_event.dart';

/// Provider that listens to Gateway events and routes them
/// to appropriate providers.
///
/// This provider:
/// - Watches `isConnectedProvider` to know when connected
/// - Subscribes to `connectionEventsProvider` when connected
/// - Routes events to streaming and chat providers
/// - Disposes subscription on provider disposal
final gatewayEventNotifierProvider = Provider<void>((ref) {
  final notifier = _GatewayEventNotifier(ref);
  ref.onDispose(notifier.dispose);
  return;
});

/// Internal class that manages the event subscription
class _GatewayEventNotifier {
  final Ref _ref;
  final Logger _logger = Logger();
  StreamSubscription<GatewayEvent>? _subscription;

  _GatewayEventNotifier(this._ref) {
    _initialize();
  }

  void _initialize() {
    // Watch connection state changes
    _ref.listen<bool>(isConnectedProvider, (previous, next) {
      if (next && !previous!) {
        // Connected - subscribe to events
        _subscribeToEvents();
      } else if (!next && previous!) {
        // Disconnected - cancel subscription
        _unsubscribeFromEvents();
      }
    });

    // Check if already connected on initialization
    if (_ref.read(isConnectedProvider)) {
      _subscribeToEvents();
    }
  }

  void _subscribeToEvents() {
    _subscription?.cancel();

    final events = _ref.read(connectionEventsProvider);
    _subscription = events.listen(
      _handleEvent,
      onError: (Object error) {
        _logger.e('[GatewayEventNotifier] Event stream error: $error');
      },
    );

    _logger.i('[GatewayEventNotifier] Subscribed to Gateway events');
  }

  void _unsubscribeFromEvents() {
    _subscription?.cancel();
    _subscription = null;
    _logger.i('[GatewayEventNotifier] Unsubscribed from Gateway events');
  }

  void _handleEvent(GatewayEvent event) {
    _logger.d('[GatewayEventNotifier] Received event: ${event.event}');

    switch (event.event) {
      case GatewayEventType.chat:
        _handleChatEvent(event);
        break;

      case GatewayEventType.messageStart:
        _handleMessageStart(event);
        break;

      case GatewayEventType.messageDelta:
        _handleMessageDelta(event);
        break;

      case GatewayEventType.messageEnd:
        _handleMessageEnd(event);
        break;

      case GatewayEventType.done:
        _handleDone(event);
        break;

      case GatewayEventType.error:
        _handleError(event);
        break;

      default:
        // Ignore other event types
        break;
    }
  }

  /// Handle Gateway 'chat' events (state: delta or final)
  void _handleChatEvent(GatewayEvent event) {
    final payload = event.payload;
    if (payload == null) {
      _logger.w('[GatewayEventNotifier] chat event missing payload');
      return;
    }

    final state = payload['state'] as String?;
    final sessionKey = payload['sessionKey'] as String?;

    _logger.d(
      '[GatewayEventNotifier] chat event state=$state, sessionKey=$sessionKey',
    );

    if (state == 'final') {
      // Final message - create the assistant message directly
      _handleChatFinal(payload);
    }
    // Ignore delta events - we'll use the final message
  }

  void _handleChatFinal(Map<String, dynamic> payload) {
    final message = payload['message'] as Map<String, dynamic>?;
    if (message == null) {
      _logger.w('[GatewayEventNotifier] chat final missing message');
      return;
    }

    // Extract full text content
    String? fullText;
    if (message['content'] is List) {
      final content = message['content'] as List;
      final textParts = content
          .whereType<Map<String, dynamic>>()
          .where((part) => part['type'] == 'text')
          .map((part) => part['text'] as String?)
          .whereType<String>();
      fullText = textParts.join();
    } else if (message['content'] is String) {
      fullText = message['content'] as String;
    }

    if (fullText == null || fullText.isEmpty) {
      _logger.w('[GatewayEventNotifier] chat final has no text content');
      return;
    }

    _logger.i(
      '[GatewayEventNotifier] Creating assistant message: '
      '${fullText.length > 50 ? fullText.substring(0, 50) : fullText}...',
    );

    // Add the message directly to chat provider
    _ref.read(chatProvider.notifier).addAssistantMessageFromText(fullText);
  }

  void _handleMessageStart(GatewayEvent event) {
    final payload = event.payload;
    if (payload == null) {
      _logger.w('[GatewayEventNotifier] message.start missing payload');
      return;
    }

    // Extract sessionId from payload
    final sessionId = payload['sessionId'] as String?;
    if (sessionId == null) {
      _logger.w('[GatewayEventNotifier] message.start missing sessionId');
      return;
    }

    _logger.i(
      '[GatewayEventNotifier] Starting streaming for session: $sessionId',
    );
    _ref.read(streamingProvider.notifier).startStreaming(sessionId: sessionId);
  }

  void _handleMessageDelta(GatewayEvent event) {
    final payload = event.payload;
    if (payload == null) {
      _logger.w('[GatewayEventNotifier] message.delta missing payload');
      return;
    }

    // Extract text from payload
    // The delta can be in 'text', 'delta', or nested in 'content'
    String? text;
    if (payload['text'] != null) {
      text = payload['text'] as String;
    } else if (payload['delta'] != null) {
      text = payload['delta'] as String;
    } else if (payload['content'] is String) {
      text = payload['content'] as String;
    } else if (payload['content'] is List) {
      // Handle content array with text parts
      final content = payload['content'] as List;
      final textParts = content
          .whereType<Map<String, dynamic>>()
          .where((part) => part['type'] == 'text')
          .map((part) => part['text'] as String?)
          .whereType<String>();
      text = textParts.join();
    }

    if (text == null || text.isEmpty) {
      _logger.d('[GatewayEventNotifier] message.delta has no text content');
      return;
    }

    _ref.read(streamingProvider.notifier).appendTextChunk(text);
  }

  void _handleMessageEnd(GatewayEvent event) {
    _logger.i('[GatewayEventNotifier] Message streaming ended');
    _ref.read(streamingProvider.notifier).finishStreaming();
  }

  void _handleDone(GatewayEvent event) {
    _logger.i('[GatewayEventNotifier] Received done event');
    _ref.read(chatProvider.notifier).stopReceiving();
  }

  void _handleError(GatewayEvent event) {
    final payload = event.payload;
    var errorMessage = 'Unknown error';

    if (payload != null) {
      // Try to extract error message from various payload formats
      errorMessage =
          payload['message'] as String? ??
          payload['error'] as String? ??
          'Unknown error';
    }

    _logger.e('[GatewayEventNotifier] Error event: $errorMessage');
    _ref.read(chatProvider.notifier).setError(errorMessage);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _logger.i('[GatewayEventNotifier] Disposed');
  }
}
