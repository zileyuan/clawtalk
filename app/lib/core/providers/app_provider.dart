import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'theme_provider.dart';

/// Global provider container key for app-wide state management.
final appProviderContainer = ProviderContainer();

/// Provider for the global navigator key.
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

/// Provider for the current app lifecycle state.
final appLifecycleProvider = StreamProvider<AppLifecycleState>((ref) async* {
  // In a real app, this would listen to app lifecycle events
  yield AppLifecycleState.resumed;
});

/// Provider for checking if app is in foreground.
final isAppForegroundProvider = Provider<bool>((ref) {
  final lifecycle = ref.watch(appLifecycleProvider);
  return lifecycle.when(
    data: (state) => state == AppLifecycleState.resumed,
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Provider for the current app version.
final appVersionProvider = Provider<String>((ref) {
  // TODO: Load from package_info_plus
  return '1.0.0';
});

/// Provider for the current build number.
final buildNumberProvider = Provider<String>((ref) {
  // TODO: Load from package_info_plus
  return '1';
});

/// Combined app info provider.
final appInfoProvider = Provider<AppInfo>((ref) {
  final version = ref.watch(appVersionProvider);
  final buildNumber = ref.watch(buildNumberProvider);

  return AppInfo(
    version: version,
    buildNumber: buildNumber,
    fullVersion: '$version+$buildNumber',
  );
});

/// App information data class.
class AppInfo {
  /// Creates app info.
  const AppInfo({
    required this.version,
    required this.buildNumber,
    required this.fullVersion,
  });

  /// App version.
  final String version;

  /// Build number.
  final String buildNumber;

  /// Full version string.
  final String fullVersion;
}

/// Provider for tracking initialization state.
final appInitializationProvider =
    StateNotifierProvider<AppInitializationNotifier, AppInitializationState>(
  (ref) => AppInitializationNotifier(),
);

/// Notifier for app initialization state.
class AppInitializationNotifier extends StateNotifier<AppInitializationState> {
  AppInitializationNotifier() : super(AppInitializationState.initial);

  /// Initialize the app.
  Future<void> initialize() async {
    state = AppInitializationState.loading;

    try {
      // TODO: Add actual initialization logic
      // - Load preferences
      // - Initialize services
      // - Setup notifications
      // - etc.

      await Future.delayed(const Duration(seconds: 1)); // Simulated delay

      state = AppInitializationState.ready;
    } catch (e) {
      state = AppInitializationState.error;
    }
  }

  /// Mark app as initialized.
  void markAsReady() {
    state = AppInitializationState.ready;
  }

  /// Reset to initial state.
  void reset() {
    state = AppInitializationState.initial;
  }
}

/// App initialization states.
enum AppInitializationState {
  /// Initial state before initialization.
  initial,

  /// Currently loading.
  loading,

  /// Fully initialized and ready.
  ready,

  /// Error during initialization.
  error,
}

/// Provider for network connectivity state.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // TODO: Implement with connectivity_plus
  // For now, assume always connected
  yield true;
});

/// Provider for checking if device is online.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (connected) => connected,
    loading: () => true,
    error: (_, __) => false,
  );
});

/// Provider for showing offline banner.
final showOfflineBannerProvider = Provider<bool>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  return !isOnline;
});
