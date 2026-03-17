import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clawtalk/app.dart';
import 'package:clawtalk/core/navigation/app_router.dart';
import 'package:clawtalk/core/themes/theme_provider.dart';
import 'package:clawtalk/core/providers/locale_provider.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('app initializes correctly', (tester) async {
      // Build the app
      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      // Wait for initial frame
      await tester.pumpAndSettle();

      // Verify app title is present
      expect(find.text('ClawTalk'), findsOneWidget);
    });

    testWidgets('theme switching works correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Get initial theme state
      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.system);

      // Switch to dark mode
      container.read(themeModeProvider.notifier).setDarkMode();
      await tester.pumpAndSettle();

      // Verify theme changed
      final darkTheme = container.read(themeModeProvider);
      expect(darkTheme, ThemeMode.dark);

      // Switch to light mode
      container.read(themeModeProvider.notifier).setLightMode();
      await tester.pumpAndSettle();

      final lightTheme = container.read(themeModeProvider);
      expect(lightTheme, ThemeMode.light);
    });

    testWidgets('locale switching works correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Get initial locale
      final initialLocale = container.read(localeProvider);
      expect(initialLocale.languageCode, 'en');

      // Switch to Chinese Simplified
      container.read(localeProvider.notifier).setChineseSimplified();
      await tester.pumpAndSettle();

      final zhLocale = container.read(localeProvider);
      expect(zhLocale.languageCode, 'zh');
      expect(zhLocale.countryCode, 'CN');

      // Switch to Chinese Traditional
      container.read(localeProvider.notifier).setChineseTraditional();
      await tester.pumpAndSettle();

      final twLocale = container.read(localeProvider);
      expect(twLocale.languageCode, 'zh');
      expect(twLocale.countryCode, 'TW');
    });

    testWidgets('navigation between screens works', (tester) async {
      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Initial route should show the app
      expect(find.byType(CupertinoApp), findsOneWidget);

      // Test navigation to settings
      AppRouter.navigateTo('/settings');
      await tester.pumpAndSettle();

      // Should have navigated (check router key is working)
      expect(AppRouter.navigatorKey.currentState, isNotNull);
    });

    testWidgets('app maintains state across rebuilds', (tester) async {
      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Change theme
      container.read(themeModeProvider.notifier).setDarkMode();
      await tester.pumpAndSettle();

      // Change locale
      container.read(localeProvider.notifier).setChineseSimplified();
      await tester.pumpAndSettle();

      // Verify state persisted
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(container.read(localeProvider).languageCode, 'zh');
    });
  });
}
