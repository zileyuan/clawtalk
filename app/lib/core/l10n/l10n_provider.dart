import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:easy_localization/easy_localization.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void setLocale(Locale locale) {
    state = locale;
  }

  void setEnglish() => setLocale(const Locale('en'));
  void setSimplifiedChinese() => setLocale(const Locale('zh'));
  void setTraditionalChinese() => setLocale(const Locale('zh', 'TW'));

  static List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];
}
