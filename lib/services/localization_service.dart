import 'package:flutter/material.dart';
import 'package:notio/services/storage_service.dart';

class LocalizationService {
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('de'), // German
    Locale('zh'), // Chinese
    // Add more as needed, but for now we define a few key ones or all 72
    // If we map exact strings to codes, we need a map.
  ];

  // Map language names (from languages.dart) to Locale codes
  static Locale getLocaleFromLanguage(String language) {
    switch (language) {
      case 'Spanish':
        return const Locale('es');
      case 'French':
        return const Locale('fr');
      case 'German':
        return const Locale('de');
      case 'Chinese (Simplified)':
        return const Locale('zh');
      // ... Add mapping for all 72 languages ideally, defaulting to English
      default:
        return const Locale('en');
    }
  }

  static String getLanguageFromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'zh':
        return 'Chinese (Simplified)';
      default:
        return 'English';
    }
  }

  // Notifier for app-wide locale changes
  static final ValueNotifier<Locale> currentLocale =
      ValueNotifier(const Locale('en'));

  static void changeLocale(String language) {
    final locale = getLocaleFromLanguage(language);
    currentLocale.value = locale;
    StorageService().saveLanguage(language);
  }

  static void init() {
    final savedLanguage = StorageService().getLanguage();
    if (savedLanguage != null) {
      currentLocale.value = getLocaleFromLanguage(savedLanguage);
    }
  }
}
