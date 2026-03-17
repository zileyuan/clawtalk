/// Route names for the application.
///
/// All route paths are defined here to ensure consistency
/// throughout the app.
class AppRoutes {
  AppRoutes._();

  // Root
  static const String root = '/';

  // Connection routes
  static const String connections = '/connections';
  static const String connectionDetail = '/connections/:id';
  static const String connectionAdd = '/connections/add';
  static const String connectionEdit = '/connections/edit/:id';

  // Chat routes
  static const String chat = '/chat/:id';
  static const String chatList = '/chats';

  // Settings routes
  static const String settings = '/settings';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsLanguage = '/settings/language';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsAbout = '/settings/about';

  // Help routes
  static const String help = '/help';
  static const String faq = '/help/faq';

  /// Helper to build connection detail path.
  static String connectionDetailPath(String id) => '/connections/$id';

  /// Helper to build connection edit path.
  static String connectionEditPath(String id) => '/connections/edit/$id';

  /// Helper to build chat path.
  static String chatPath(String id) => '/chat/$id';
}

/// Route parameter names.
class RouteParams {
  RouteParams._();

  static const String id = 'id';
}

/// Route query parameter names.
class QueryParams {
  QueryParams._();

  static const String search = 'search';
  static const String filter = 'filter';
  static const String sort = 'sort';
  static const String returnTo = 'returnTo';
}
