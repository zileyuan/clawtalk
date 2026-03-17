import 'package:flutter/cupertino.dart';

import 'app_router.dart';
import 'app_routes.dart';

/// Navigation service for programmatic navigation.
///
/// Provides a service-based approach to navigation that can be
/// easily mocked for testing and used outside of widget context.
class NavigationService {
  /// Navigate to connections list.
  static Future<void> toConnections() async {
    await AppRouter.navigateAndRemoveAll(AppRoutes.connections);
  }

  /// Navigate to connection detail.
  static Future<void> toConnectionDetail(String id) async {
    await AppRouter.navigateTo(
      AppRoutes.connectionDetail,
      arguments: {'id': id},
    );
  }

  /// Navigate to add connection.
  static Future<void> toAddConnection() async {
    await AppRouter.navigateTo(AppRoutes.connectionAdd);
  }

  /// Navigate to edit connection.
  static Future<void> toEditConnection(String id) async {
    await AppRouter.navigateTo(AppRoutes.connectionEdit, arguments: {'id': id});
  }

  /// Navigate to chat.
  static Future<void> toChat(String id) async {
    await AppRouter.navigateTo(AppRoutes.chat, arguments: {'id': id});
  }

  /// Navigate to chat list.
  static Future<void> toChatList() async {
    await AppRouter.navigateTo(AppRoutes.chatList);
  }

  /// Navigate to settings.
  static Future<void> toSettings() async {
    await AppRouter.navigateTo(AppRoutes.settings);
  }

  /// Navigate to appearance settings.
  static Future<void> toAppearanceSettings() async {
    await AppRouter.navigateTo(AppRoutes.settingsAppearance);
  }

  /// Navigate to language settings.
  static Future<void> toLanguageSettings() async {
    await AppRouter.navigateTo(AppRoutes.settingsLanguage);
  }

  /// Navigate to notifications settings.
  static Future<void> toNotificationsSettings() async {
    await AppRouter.navigateTo(AppRoutes.settingsNotifications);
  }

  /// Navigate to about.
  static Future<void> toAbout() async {
    await AppRouter.navigateTo(AppRoutes.settingsAbout);
  }

  /// Navigate back.
  static void back<T>([T? result]) {
    AppRouter.goBack(result);
  }

  /// Navigate back to connections.
  static void backToConnections() {
    AppRouter.popUntil(AppRoutes.connections);
  }

  /// Check if can pop.
  static bool get canPop => AppRouter.canPop();

  /// Get current route name.
  static String? get currentRoute => AppRouter.currentRoute;
}

/// Extension on BuildContext for easy navigation.
extension NavigationContextExtension on BuildContext {
  /// Navigate to a route.
  Future<void> navigateTo(
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    await Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  /// Navigate to a route and replace.
  Future<void> navigateAndReplace(
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    await Navigator.of(
      this,
    ).pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate to a route and remove all previous.
  Future<void> navigateAndRemoveAll(
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    await Navigator.of(this).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop current route.
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// Check if can pop.
  bool get canPop => Navigator.of(this).canPop();

  /// Pop until route.
  void popUntil(String routeName) {
    Navigator.of(this).popUntil((route) => route.settings.name == routeName);
  }
}
