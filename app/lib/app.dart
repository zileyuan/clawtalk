import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/providers/providers.dart';
import 'core/themes/app_theme.dart';

class ClawTalkApp extends ConsumerWidget {
  const ClawTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return CupertinoApp(
      title: 'ClawTalk',
      navigatorKey: AppRouter.navigatorKey,
      theme: themeMode == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.cupertinoTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: AppRoutes.root,
      onGenerateRoute: AppRouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
