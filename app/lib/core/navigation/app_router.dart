import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/connection/domain/entities/connection_config.dart';
import '../../features/connection/presentation/providers/connection_list_provider.dart';
import '../../features/connection/presentation/screens/add_connection_screen.dart';
import '../../features/connection/presentation/screens/connection_list_screen.dart';
import '../../features/connection/presentation/screens/edit_connection_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/messaging/presentation/screens/session_list_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/language_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import 'app_routes.dart';

/// Simple route-based navigation for the app.
///
/// Provides a straightforward navigation system using Flutter's
/// built-in Navigator 2.0 concepts without external dependencies.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate to a named route.
  static Future<void> navigateTo(
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      await navigator.pushNamed(routeName, arguments: arguments);
    }
  }

  /// Navigate to a named route and remove all previous routes.
  static Future<void> navigateAndRemoveAll(
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      await navigator.pushNamedAndRemoveUntil(
        routeName,
        (route) => false,
        arguments: arguments,
      );
    }
  }

  /// Navigate to a named route and replace current.
  static Future<void> navigateAndReplace(
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      await navigator.pushReplacementNamed(routeName, arguments: arguments);
    }
  }

  /// Go back.
  static void goBack<T>([T? result]) {
    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop(result);
    }
  }

  /// Check if can pop.
  static bool canPop() {
    final navigator = navigatorKey.currentState;
    return navigator != null && navigator.canPop();
  }

  /// Pop until route with name.
  static void popUntil(String routeName) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil((route) => route.settings.name == routeName);
    }
  }

  /// Get current route name.
  static String? get currentRoute {
    String? current;
    navigatorKey.currentState?.popUntil((route) {
      current = route.settings.name;
      return true;
    });
    return current;
  }
}

/// Route generator for the app.
class AppRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name;
    final args = settings.arguments as Map<String, dynamic>?;

    switch (name) {
      case AppRoutes.root:
      case AppRoutes.connections:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const ConnectionListScreen(),
        );

      case AppRoutes.connectionAdd:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const AddConnectionScreen(),
        );

      case AppRoutes.connectionEdit:
        final id = args?['id'] as String?;
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => _EditConnectionLoader(connectionId: id),
        );

      case AppRoutes.connectionDetail:
        final id = args?['id'] as String?;
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => _ConnectionDetailPlaceholder(connectionId: id),
        );

      case AppRoutes.chat:
        final id = args?['id'] as String?;
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ChatScreen(sessionId: id),
        );

      case AppRoutes.chatList:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const SessionListScreen(),
        );

      case AppRoutes.settings:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      case AppRoutes.settingsAppearance:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const ThemeSettingsScreen(),
        );

      case AppRoutes.settingsLanguage:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const LanguageSettingsScreen(),
        );

      case AppRoutes.settingsNotifications:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const _NotificationsSettingsPlaceholder(),
        );

      case AppRoutes.settingsAbout:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const AboutScreen(),
        );

      default:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}

/// Wrapper widget that loads connection data and renders EditConnectionScreen
class _EditConnectionLoader extends ConsumerWidget {
  final String? connectionId;

  const _EditConnectionLoader({this.connectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (connectionId == null) {
      return const _ErrorScreen(message: 'Connection ID is required');
    }

    final state = ref.watch(connectionListProvider);
    final connection = state.connections
        .where((c) => c.id == connectionId)
        .firstOrNull;

    if (connection == null) {
      return const _ErrorScreen(message: 'Connection not found');
    }

    return EditConnectionScreen(connection: connection);
  }
}

/// Placeholder for connection detail screen (not yet implemented)
class _ConnectionDetailPlaceholder extends StatelessWidget {
  final String? connectionId;

  const _ConnectionDetailPlaceholder({this.connectionId});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Connection Details'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.link,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Detail Screen\nID: $connectionId',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for notifications settings screen (not yet implemented)
class _NotificationsSettingsPlaceholder extends StatelessWidget {
  const _NotificationsSettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Notifications'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.bell_fill,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Notifications Settings\nComing Soon',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: () => AppRouter.goBack(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for when required arguments are missing
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Error')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: () => AppRouter.goBack(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen shown when a route is not found.
class NotFoundScreen extends StatelessWidget {
  /// Creates a not found screen.
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Page Not Found'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: () => AppRouter.goBack(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
