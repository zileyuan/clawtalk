/// Dependency Injection barrel file
///
/// Export all DI modules from this file for convenient imports.
///
/// Example:
/// ```dart
/// import 'package:clawtalk/core/di/di.dart';
/// ```
///
/// This gives you access to:
/// - [ServiceLocator] - Service locator pattern for imperative access
/// - [serviceLocator] - Global service locator instance
/// - All Riverpod providers for dependency injection
/// - Testing utilities for provider overrides

// Service Locator
export 'service_locator.dart';

// Providers
export 'providers.dart';
