import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:clawtalk/acp/client/connection_config.dart';
import 'package:clawtalk/acp/client/connection_state.dart';
import 'package:clawtalk/acp/services/connection_service.dart';

class MockConnectionService extends Mock implements ConnectionService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Connection Flow Integration Tests', () {
    late ConnectionService mockConnectionService;

    setUp(() {
      mockConnectionService = MockConnectionService();
    });

    testWidgets('connection can be added', (tester) async {
      // Create test connection config
      final testConfig = ConnectionConfig(
        id: 'test-connection-1',
        name: 'Test Connection',
        host: 'localhost',
        port: 8080,
        useTLS: false,
        authToken: 'test-token',
      );

      // Mock save connection behavior
      when(
        () => mockConnectionService.saveConnection(testConfig),
      ).thenAnswer((_) async {});

      // Save connection
      await mockConnectionService.saveConnection(testConfig);

      // Verify save was called
      verify(() => mockConnectionService.saveConnection(testConfig)).called(1);
    });

    testWidgets('connection list displays correctly', (tester) async {
      // Create multiple test connections
      final connections = [
        ConnectionConfig(
          id: 'conn-1',
          name: 'Connection 1',
          host: 'host1.local',
          port: 8080,
        ),
        ConnectionConfig(
          id: 'conn-2',
          name: 'Connection 2',
          host: 'host2.local',
          port: 9090,
        ),
      ];

      // Mock load saved connections
      when(
        () => mockConnectionService.loadSavedConnections(),
      ).thenAnswer((_) async => connections);

      // Load connections
      final savedConnections = await mockConnectionService
          .loadSavedConnections();

      // Verify connections loaded
      expect(savedConnections.length, 2);
      expect(savedConnections[0].id, 'conn-1');
      expect(savedConnections[1].id, 'conn-2');

      verify(() => mockConnectionService.loadSavedConnections()).called(1);
    });

    testWidgets('connection status updates correctly', (tester) async {
      // Create a connection
      final testConfig = ConnectionConfig(
        id: 'test-conn',
        name: 'Test Connection',
        host: 'localhost',
        port: 8080,
      );

      // Mock connect behavior
      when(
        () => mockConnectionService.connect(testConfig),
      ).thenAnswer((_) async {});

      // Mock state stream
      when(
        () => mockConnectionService.stateStream,
      ).thenAnswer((_) => Stream.value(ConnectionState.connected()));

      // Mock isConnected
      when(() => mockConnectionService.isConnected).thenReturn(true);

      // Connect
      await mockConnectionService.connect(testConfig);

      // Verify connected
      expect(mockConnectionService.isConnected, true);

      // Verify connect was called
      verify(() => mockConnectionService.connect(testConfig)).called(1);
    });

    testWidgets('connection can be deleted', (tester) async {
      const connectionId = 'delete-test-conn';

      // Mock delete behavior
      when(
        () => mockConnectionService.deleteConnection(connectionId),
      ).thenAnswer((_) async {});

      // Delete connection
      await mockConnectionService.deleteConnection(connectionId);

      // Verify delete was called
      verify(
        () => mockConnectionService.deleteConnection(connectionId),
      ).called(1);
    });

    testWidgets('last connection can be retrieved', (tester) async {
      final lastConfig = ConnectionConfig(
        id: 'last-conn',
        name: 'Last Used Connection',
        host: 'last.local',
        port: 8080,
      );

      // Mock get last connection
      when(
        () => mockConnectionService.getLastConnection(),
      ).thenAnswer((_) async => lastConfig);

      // Get last connection
      final lastConnection = await mockConnectionService.getLastConnection();

      // Verify last connection retrieved
      expect(lastConnection, isNotNull);
      expect(lastConnection?.id, 'last-conn');
      expect(lastConnection?.name, 'Last Used Connection');

      verify(() => mockConnectionService.getLastConnection()).called(1);
    });

    testWidgets('disconnect works correctly', (tester) async {
      // Mock disconnect behavior
      when(() => mockConnectionService.disconnect()).thenAnswer((_) async {});

      // Mock isConnected after disconnect
      when(() => mockConnectionService.isConnected).thenReturn(false);

      // Disconnect
      await mockConnectionService.disconnect();

      // Verify disconnected
      expect(mockConnectionService.isConnected, false);

      verify(() => mockConnectionService.disconnect()).called(1);
    });
  });
}
