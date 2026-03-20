import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/providers/connection_provider.dart';
import 'core/providers/providers.dart';
import 'core/themes/app_theme.dart';
import 'features/messaging/presentation/providers/gateway_event_notifier.dart';

class ClawTalkApp extends ConsumerWidget {
  const ClawTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Start event listener when connected to Gateway
    final isConnected = ref.watch(isConnectedProvider);
    if (isConnected) {
      ref.watch(gatewayEventNotifierProvider);
    }

    return CupertinoApp(
      title: 'appName'.tr(),
      navigatorKey: AppRouter.navigatorKey,
      theme: themeMode == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.cupertinoTheme,
      locale: locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      initialRoute: AppRoutes.root,
      onGenerateRoute: AppRouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
