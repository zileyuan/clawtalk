import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../acp/client/acp_client.dart';
import '../../acp/client/acp_client_impl.dart';
import '../../acp/services/connection_service.dart';
import '../../acp/services/message_service.dart';
import '../../platform/platform_interface.dart';
import '../../platform/platform_provider.dart';
import '../data/datasources/local/preferences_service.dart';
import '../data/datasources/local/secure_storage_service.dart';

/// Service locator for dependency injection
///
/// Provides centralized service initialization and access.
/// Use this for imperative service access outside of widget tree.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Services
  late final SecureStorageService _secureStorage;
  late final PreferencesService _preferences;
  late final Logger _logger;
  late final ConnectionService _connectionService;
  late final MessageService _messageService;
  late final PlatformInterface _platformInterface;

  // Initialization state
  bool _initialized = false;

  /// Whether the service locator has been initialized
  bool get isInitialized => _initialized;

  /// Initialize all services
  ///
  /// Must be called before accessing any services.
  /// Should be called in main() before runApp().
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Initialize local storage services
    _secureStorage = SecureStorageService();
    _preferences = await PreferencesService.create();

    // Initialize logger
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );

    // Initialize platform interface
    _platformInterface = _getPlatformImplementation();

    // Initialize ACP services
    _connectionService = ConnectionService(logger: _logger);
    _messageService = MessageService(logger: _logger);

    _initialized = true;
    _logger.i('ServiceLocator initialized successfully');
  }

  /// Get secure storage service
  SecureStorageService get secureStorage {
    _ensureInitialized();
    return _secureStorage;
  }

  /// Get preferences service
  PreferencesService get preferences {
    _ensureInitialized();
    return _preferences;
  }

  /// Get logger instance
  Logger get logger {
    _ensureInitialized();
    return _logger;
  }

  /// Get connection service
  ConnectionService get connectionService {
    _ensureInitialized();
    return _connectionService;
  }

  /// Get message service
  MessageService get messageService {
    _ensureInitialized();
    return _messageService;
  }

  /// Get platform interface
  PlatformInterface get platformInterface {
    _ensureInitialized();
    return _platformInterface;
  }

  /// Create a new ACP client instance
  ///
  /// This creates a fresh client instance. Use [connectionService]
  /// for managing the primary connection.
  AcpClient createAcpClient() {
    _ensureInitialized();
    return AcpClientImpl();
  }

  /// Dispose all services
  ///
  /// Should be called when the app is shutting down.
  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }

    _logger.i('Disposing ServiceLocator...');

    await _connectionService.dispose();
    _messageService.dispose();

    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
  }

  PlatformInterface _getPlatformImplementation() {
    // Import dynamically to avoid platform-specific imports
    if (const bool.fromEnvironment('dart.library.io')) {
      try {
        // This will be resolved at runtime based on platform
        return _createPlatformInterface();
      } catch (e) {
        return FallbackPlatformInterface();
      }
    }
    return FallbackPlatformInterface();
  }

  PlatformInterface _createPlatformInterface() {
    // Delegate to platform provider's implementation
    // This is a workaround to avoid direct imports
    return _PlatformInterfaceHolder.instance;
  }
}

/// Holder for platform interface to avoid import issues
class _PlatformInterfaceHolder {
  static PlatformInterface? _instance;

  static PlatformInterface get instance {
    _instance ??= FallbackPlatformInterface();
    return _instance!;
  }

  static void setInstance(PlatformInterface interface) {
    _instance = interface;
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();
