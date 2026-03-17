import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:clawtalk/app.dart';
import 'package:clawtalk/core/themes/theme_provider.dart';
import 'package:clawtalk/core/providers/locale_provider.dart';

void main() {
  group('ClawTalkApp Widget Tests', () {
    testWidgets('ClawTalkApp builds correctly with default state', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: ClawTalkApp()));

      // Wait for the app to build
      await tester.pumpAndSettle();

      // Verify app is built
      expect(find.byType(CupertinoApp), findsOneWidget);

      // Verify app title
      expect(find.text('ClawTalk'), findsOneWidget);
    });

    testWidgets('theme is applied correctly', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );

      // Verify theme is not null
      expect(cupertinoApp.theme, isNotNull);
    });

    testWidgets('dark theme is applied when set', (tester) async {
      final container = ProviderContainer();

      // Set dark mode
      container.read(themeModeProvider.notifier).setDarkMode();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Verify dark theme is set
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Get CupertinoApp and verify theme brightness
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );
      expect(cupertinoApp.theme?.brightness, Brightness.dark);
    });

    testWidgets('light theme is applied when set', (tester) async {
      final container = ProviderContainer();

      // Set light mode
      container.read(themeModeProvider.notifier).setLightMode();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Verify light theme is set
      expect(container.read(themeModeProvider), ThemeMode.light);

      // Get CupertinoApp and verify theme brightness
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );
      expect(cupertinoApp.theme?.brightness, Brightness.light);
    });

    testWidgets('locale is applied correctly', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );

      // Verify locale is set
      expect(cupertinoApp.locale, isNotNull);
    });

    testWidgets('English locale is applied', (tester) async {
      final container = ProviderContainer();

      // Set English locale
      container.read(localeProvider.notifier).setEnglish();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Verify English locale
      expect(container.read(localeProvider).languageCode, 'en');

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );
      expect(cupertinoApp.locale?.languageCode, 'en');
    });

    testWidgets('Chinese Simplified locale is applied', (tester) async {
      final container = ProviderContainer();

      // Set Chinese Simplified locale
      container.read(localeProvider.notifier).setChineseSimplified();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Verify Chinese locale
      expect(container.read(localeProvider).languageCode, 'zh');
      expect(container.read(localeProvider).countryCode, 'CN');

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );
      expect(cupertinoApp.locale?.languageCode, 'zh');
    });

    testWidgets('Chinese Traditional locale is applied', (tester) async {
      final container = ProviderContainer();

      // Set Chinese Traditional locale
      container.read(localeProvider.notifier).setChineseTraditional();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Verify Traditional Chinese locale
      expect(container.read(localeProvider).languageCode, 'zh');
      expect(container.read(localeProvider).countryCode, 'TW');

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );
      expect(cupertinoApp.locale?.languageCode, 'zh');
    });

    testWidgets('theme and locale can be changed dynamically', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        ProviderScope(parent: container, child: const ClawTalkApp()),
      );

      await tester.pumpAndSettle();

      // Change theme dynamically
      container.read(themeModeProvider.notifier).setDarkMode();
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Change locale dynamically
      container.read(localeProvider.notifier).setChineseSimplified();
      await tester.pumpAndSettle();
      expect(container.read(localeProvider).languageCode, 'zh');

      // Get CupertinoApp and verify both changed
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );
      expect(cupertinoApp.theme?.brightness, Brightness.dark);
      expect(cupertinoApp.locale?.languageCode, 'zh');
    });

    testWidgets('debug banner is hidden', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ClawTalkApp()));

      await tester.pumpAndSettle();

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );

      // Verify debug banner is hidden
      expect(cupertinoApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('navigator key is set', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ClawTalkApp()));

      await tester.pumpAndSettle();

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );

      // Verify navigator key is set
      expect(cupertinoApp.navigatorKey, isNotNull);
    });

    testWidgets('localizations delegates are configured', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ClawTalkApp()));

      await tester.pumpAndSettle();

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );

      // Verify localizations delegates are set
      expect(cupertinoApp.localizationsDelegates, isNotNull);
      expect(cupertinoApp.localizationsDelegates?.length, greaterThan(0));
    });

    testWidgets('supported locales are configured', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ClawTalkApp()));

      await tester.pumpAndSettle();

      // Get CupertinoApp
      final cupertinoApp = tester.widget<CupertinoApp>(
        find.byType(CupertinoApp),
      );

      // Verify supported locales are set
      expect(cupertinoApp.supportedLocales, isNotNull);
      expect(cupertinoApp.supportedLocales?.length, greaterThan(0));
    });
  });
}
