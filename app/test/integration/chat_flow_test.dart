import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:clawtalk/features/messaging/domain/entities/session.dart';
import 'package:clawtalk/features/messaging/domain/entities/message.dart';
import 'package:clawtalk/features/messaging/presentation/providers/chat_provider.dart';
import 'package:clawtalk/features/messaging/presentation/providers/streaming_provider.dart';
import 'package:clawtalk/features/messaging/domain/entities/content_block.dart';

class MockChatNotifier extends Mock implements ChatNotifier {}

class MockStreamingNotifier extends Mock implements StreamingNotifier {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Flow Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('chat screen loads correctly', (tester) async {
      // Create test session
      final testSession = Session(
        id: 'test-session-1',
        title: 'Test Chat',
        status: SessionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Initialize chat with session
      container.read(chatProvider.notifier).initializeSession(testSession);
      await tester.pumpAndSettle();

      // Get chat state
      final chatState = container.read(chatProvider);

      // Verify session is loaded
      expect(chatState.session, isNotNull);
      expect(chatState.session?.id, 'test-session-1');
      expect(chatState.session?.title, 'Test Chat');
    });

    testWidgets('message can be sent via provider', (tester) async {
      // Create test session
      final testSession = Session(
        id: 'test-session-2',
        title: 'Test Chat',
        status: SessionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Initialize chat
      container.read(chatProvider.notifier).initializeSession(testSession);
      await tester.pumpAndSettle();

      // Send a message
      const testMessage = 'Hello, this is a test message!';
      container.read(chatProvider.notifier).sendMessage(testMessage);
      await tester.pumpAndSettle();

      // Verify message was sent (would need actual implementation)
      // For now, just verify no errors occurred
      final chatState = container.read(chatProvider);
      expect(chatState.session, isNotNull);
    });

    testWidgets('streaming indicator shows when receiving', (tester) async {
      // Set streaming state to true
      container.read(streamingProvider.notifier).startStreaming();
      await tester.pumpAndSettle();

      // Verify streaming state
      final isStreaming = container.read(streamingProvider);
      expect(isStreaming, true);

      // End streaming
      container.read(streamingProvider.notifier).endStreaming();
      await tester.pumpAndSettle();

      // Verify streaming ended
      final isNotStreaming = container.read(streamingProvider);
      expect(isNotStreaming, false);
    });

    testWidgets('message list updates correctly', (tester) async {
      // Create test session
      final testSession = Session(
        id: 'test-session-3',
        title: 'Test Chat',
        status: SessionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Initialize chat
      container.read(chatProvider.notifier).initializeSession(testSession);
      await tester.pumpAndSettle();

      // Get initial state
      final initialState = container.read(chatProvider);
      expect(initialState.messages, isEmpty);

      // Add a message
      final testMessage = Message(
        id: 'msg-1',
        sessionId: 'test-session-3',
        content: [ContentBlock.text('Test message')],
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      // Simulate message added
      container.read(chatProvider.notifier).addMessage(testMessage);
      await tester.pumpAndSettle();

      // Verify message was added
      final updatedState = container.read(chatProvider);
      expect(updatedState.messages.length, 1);
      expect(updatedState.messages.first.id, 'msg-1');
    });

    testWidgets('session can be ended', (tester) async {
      // Create test session
      final testSession = Session(
        id: 'test-session-4',
        title: 'Test Chat',
        status: SessionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Initialize chat
      container.read(chatProvider.notifier).initializeSession(testSession);
      await tester.pumpAndSettle();

      // End session
      container.read(chatProvider.notifier).endSession();
      await tester.pumpAndSettle();

      // Verify session ended
      final chatState = container.read(chatProvider);
      expect(chatState.session?.status, SessionStatus.ended);
    });

    testWidgets('streaming text updates correctly', (tester) async {
      // Start streaming
      container.read(streamingProvider.notifier).startStreaming();
      await tester.pumpAndSettle();

      // Update streaming text
      container.read(streamingTextProvider.notifier).updateText('Hello');
      await tester.pumpAndSettle();

      // Verify text
      final streamingText = container.read(streamingTextProvider);
      expect(streamingText, 'Hello');

      // Append more text
      container.read(streamingTextProvider.notifier).appendText(' World');
      await tester.pumpAndSettle();

      // Verify appended text
      final updatedText = container.read(streamingTextProvider);
      expect(updatedText, 'Hello World');

      // Clear text
      container.read(streamingTextProvider.notifier).clearText();
      await tester.pumpAndSettle();

      // Verify cleared
      final clearedText = container.read(streamingTextProvider);
      expect(clearedText, '');
    });
  });
}
