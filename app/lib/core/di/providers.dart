import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../acp/client/acp_client.dart';
import '../../acp/services/connection_service.dart';
import '../../acp/services/message_service.dart';
import '../../features/connection/data/datasources/local/connection_local_data_source.dart';
import '../../features/connection/data/repositories/connection_repository_impl.dart';
import '../../features/connection/domain/repositories/connection_repository.dart';
import '../../platform/platform_interface.dart';
import '../data/datasources/local/preferences_service.dart';
import '../data/datasources/local/secure_storage_service.dart';
import 'service_locator.dart';

// =============================================================================
// CORE SERVICE PROVIDERS
// =============================================================================

/// Secure storage service provider
///
/// Provides access to secure storage for sensitive data like tokens and passwords.
/// This provider is initialized lazily and caches the service instance.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return serviceLocator.secureStorage;
});

/// Secure storage provider for testing override
///
/// Use this provider to override secure storage behavior in tests.
final secureStorageOverrideProvider = Provider<SecureStorageService?>(
  (ref) => null,
);

/// Preferences service provider
///
/// Provides access to shared preferences for non-sensitive app settings.
/// This provider is initialized lazily and caches the service instance.
final preferencesProvider = Provider<PreferencesService>((ref) {
  return serviceLocator.preferences;
});

/// Preferences provider for testing override
///
/// Use this provider to override preferences behavior in tests.
final preferencesOverrideProvider = Provider<PreferencesService?>(
  (ref) => null,
);

/// Logger provider
///
/// Provides access to the application logger instance.
final loggerProvider = Provider<Logger>((ref) {
  return serviceLocator.logger;
});

/// Logger provider for testing override
///
/// Use this provider to provide a custom logger in tests.
final loggerOverrideProvider = Provider<Logger?>((ref) => null);

// =============================================================================
// PLATFORM SERVICE PROVIDERS
// =============================================================================

/// Platform interface provider
///
/// Provides access to platform-specific services (camera, audio, file, notifications).
final platformInterfaceProvider = Provider<PlatformInterface>((ref) {
  return serviceLocator.platformInterface;
});

/// Platform interface provider for testing override
final platformInterfaceOverrideProvider = Provider<PlatformInterface?>(
  (ref) => null,
);

/// Camera service provider
///
/// Provides access to camera functionality through the platform interface.
final cameraServiceProvider = Provider<CameraService>((ref) {
  final platform = ref.watch(platformInterfaceProvider);
  return platform.camera;
});

/// Audio service provider
///
/// Provides access to audio functionality through the platform interface.
final audioServiceProvider = Provider<AudioService>((ref) {
  final platform = ref.watch(platformInterfaceProvider);
  return platform.audio;
});

/// File service provider
///
/// Provides access to file operations through the platform interface.
final fileServiceProvider = Provider<FileService>((ref) {
  final platform = ref.watch(platformInterfaceProvider);
  return platform.file;
});

/// Notification service provider
///
/// Provides access to notifications through the platform interface.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final platform = ref.watch(platformInterfaceProvider);
  return platform.notification;
});

/// Permissions service provider
///
/// Provides access to platform permissions.
final permissionsProvider = Provider<PlatformPermissions>((ref) {
  final platform = ref.watch(platformInterfaceProvider);
  return platform.permissions;
});

// =============================================================================
// ACP SERVICE PROVIDERS
// =============================================================================

/// Connection service provider
///
/// Manages ACP WebSocket connections and connection state.
/// This is a singleton service shared across the app.
final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return serviceLocator.connectionService;
});

/// Connection service provider for testing override
final connectionServiceOverrideProvider = Provider<ConnectionService?>(
  (ref) => null,
);

/// Message service provider
///
/// Handles ACP message sending, receiving, and queuing.
/// This is a singleton service shared across the app.
final messageServiceProvider = Provider<MessageService>((ref) {
  return serviceLocator.messageService;
});

/// Message service provider for testing override
final messageServiceOverrideProvider = Provider<MessageService?>((ref) => null);

/// ACP client provider
///
/// Provides access to the current active ACP client from connection service.
/// Returns null if not connected.
final acpClientProvider = Provider<AcpClient?>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  try {
    return connectionService.client;
  } catch (_) {
    return null;
  }
});

/// Factory provider for creating new ACP client instances
///
/// Use this when you need a fresh client instance (e.g., for connection pools).
final acpClientFactoryProvider = Provider<AcpClient Function()>((ref) {
  return serviceLocator.createAcpClient;
});

// =============================================================================
// CONNECTION FEATURE PROVIDERS
// =============================================================================

/// Connection local data source provider
final connectionLocalDataSourceProvider = Provider<ConnectionLocalDataSource>((
  ref,
) {
  return ConnectionLocalDataSourceImpl(
    preferences: ref.watch(preferencesProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Connection repository provider
final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepositoryImpl(
    localDataSource: ref.watch(connectionLocalDataSourceProvider),
  );
});

// =============================================================================
// UTILITY PROVIDERS
// =============================================================================

/// Service locator initialization status provider
///
/// Tracks whether the service locator has been initialized.
final serviceLocatorStatusProvider = Provider<bool>((ref) {
  return serviceLocator.isInitialized;
});

/// Combined service initialization provider
///
/// Returns true when all core services are ready.
/// Use this in your app startup to wait for initialization.
final servicesReadyProvider = Provider<AsyncValue<bool>>((ref) {
  try {
    // Access all core services to ensure they're initialized
    ref.read(secureStorageProvider);
    ref.read(preferencesProvider);
    ref.read(loggerProvider);
    ref.read(platformInterfaceProvider);
    ref.read(connectionServiceProvider);
    ref.read(messageServiceProvider);
    return const AsyncValue.data(true);
  } catch (e, stack) {
    return AsyncValue.error(e, stack);
  }
});

// =============================================================================
// PROVIDER OVERRIDES FOR TESTING
// =============================================================================

/// Creates a list of provider overrides for testing
///
/// This function creates a list of overrides that can be passed to
/// [ProviderScope] in widget tests.
///
/// Example:
/// ```dart
/// testWidgets('Test with mocks', (tester) async {
///   final mockStorage = MockSecureStorage();
///   final mockPreferences = MockPreferences();
///
///   await tester.pumpWidget(
///     ProviderScope(
///       overrides: createTestOverrides(
///         secureStorage: mockStorage,
///         preferences: mockPreferences,
///       ),
///       child: MyApp(),
///     ),
///   );
/// });
/// ```
List<dynamic> createTestOverrides({
  SecureStorageService? secureStorage,
  PreferencesService? preferences,
  Logger? logger,
  ConnectionService? connectionService,
  MessageService? messageService,
  PlatformInterface? platformInterface,
}) {
  final overrides = <dynamic>[];

  if (secureStorage != null) {
    overrides.add(secureStorageProvider.overrideWithValue(secureStorage));
  }

  if (preferences != null) {
    overrides.add(preferencesProvider.overrideWithValue(preferences));
  }

  if (logger != null) {
    overrides.add(loggerProvider.overrideWithValue(logger));
  }

  if (connectionService != null) {
    overrides.add(
      connectionServiceProvider.overrideWithValue(connectionService),
    );
  }

  if (messageService != null) {
    overrides.add(messageServiceProvider.overrideWithValue(messageService));
  }

  if (platformInterface != null) {
    overrides.add(
      platformInterfaceProvider.overrideWithValue(platformInterface),
    );
  }

  return overrides;
}

/// Creates a complete test environment with all services mocked
///
/// This is useful for integration tests where you want to override
/// all external dependencies.
///
/// Example:
/// ```dart
/// testWidgets('Full app test', (tester) async {
///   await tester.pumpWidget(
///     ProviderScope(
///       overrides: createCompleteTestOverrides(
///         secureStorage: MockSecureStorage(),
///         preferences: MockPreferences(),
///       ),
///       child: MyApp(),
///     ),
///   );
/// });
/// ```
List<dynamic> createCompleteTestOverrides({
  SecureStorageService? secureStorage,
  PreferencesService? preferences,
  Logger? logger,
  ConnectionService? connectionService,
  MessageService? messageService,
  PlatformInterface? platformInterface,
}) {
  return createTestOverrides(
    secureStorage: secureStorage,
    preferences: preferences,
    logger: logger,
    connectionService: connectionService,
    messageService: messageService,
    platformInterface: platformInterface,
  );
}
