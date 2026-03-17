import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
          Locale('zh', 'TW'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const ClawTalkApp(),
      ),
    ),
  );
}
