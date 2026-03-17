import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locales for the app.
class SupportedLocales {
  SupportedLocales._();

  /// English (US).
  static const Locale english = Locale('en', 'US');

  /// Chinese (Simplified).
  static const Locale chineseSimplified = Locale('zh', 'CN');

  /// Chinese (Traditional).
  static const Locale chineseTraditional = Locale('zh', 'TW');

  /// All supported locales.
  static const List<Locale> all = [
    english,
    chineseSimplified,
    chineseTraditional,
  ];

  /// Default locale.
  static const Locale defaultLocale = english;

  /// Get locale display name.
  static String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return locale.countryCode == 'TW' ? '繁體中文' : '简体中文';
      default:
        return 'Unknown';
    }
  }
}

/// Provider for the current locale.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

/// Provider for the locale delegate.
final localeDelegateProvider = Provider<LocalizationsDelegate<void>>((ref) {
  // This would typically return your app's localizations delegate
  return DefaultCupertinoLocalizations.delegate;
});

/// Provider for checking if locale is system default.
final isSystemLocaleProvider = Provider<bool>((ref) {
  final currentLocale = ref.watch(localeProvider);
  return currentLocale == SupportedLocales.defaultLocale;
});

/// Provider for the current locale display name.
final localeDisplayNameProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return SupportedLocales.getDisplayName(locale);
});

/// Provider for RTL support.
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  // Currently no RTL locales supported, but ready for future
  return false;
});

/// Notifier for managing locale state.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(SupportedLocales.defaultLocale) {
    _loadLocale();
  }

  static const _localeKey = 'app_locale';
  static const _languageCodeKey = 'language_code';
  static const _countryCodeKey = 'country_code';

  /// Load saved locale.
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageCodeKey);
      final countryCode = prefs.getString(_countryCodeKey);

      if (languageCode != null) {
        state = Locale(languageCode, countryCode);
      }
    } catch (e) {
      // Fallback to default locale
      state = SupportedLocales.defaultLocale;
    }
  }

  /// Save locale.
  Future<void> _saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, locale.languageCode);
      if (locale.countryCode != null) {
        await prefs.setString(_countryCodeKey, locale.countryCode!);
      } else {
        await prefs.remove(_countryCodeKey);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Set locale.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _saveLocale(locale);
  }

  /// Set locale by language code.
  Future<void> setLocaleByCode(
    String languageCode, [
    String? countryCode,
  ]) async {
    final locale = Locale(languageCode, countryCode);
    await setLocale(locale);
  }

  /// Set to English.
  Future<void> setEnglish() async {
    await setLocale(SupportedLocales.english);
  }

  /// Set to Chinese Simplified.
  Future<void> setChineseSimplified() async {
    await setLocale(SupportedLocales.chineseSimplified);
  }

  /// Set to Chinese Traditional.
  Future<void> setChineseTraditional() async {
    await setLocale(SupportedLocales.chineseTraditional);
  }

  /// Reset to system default.
  Future<void> resetToDefault() async {
    await setLocale(SupportedLocales.defaultLocale);
  }

  /// Cycle through available locales.
  Future<void> cycleLocale() async {
    final currentIndex = SupportedLocales.all.indexOf(state);
    final nextIndex = (currentIndex + 1) % SupportedLocales.all.length;
    await setLocale(SupportedLocales.all[nextIndex]);
  }
}

/// Provider for date format locale.
final dateFormatLocaleProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return '${locale.languageCode}_${locale.countryCode ?? locale.languageCode.toUpperCase()}';
});

/// Provider for number format locale.
final numberFormatLocaleProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.toLanguageTag();
});
