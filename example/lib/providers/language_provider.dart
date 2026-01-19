import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A ChangeNotifier that manages the app's locale and persists the user's language preference.
class LanguageProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('en'); // Default to English

  Locale get locale => _locale;

  /// List of supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('de'), // German
    Locale('tr'), // Turkish
  ];

  LanguageProvider() {
    _loadSavedLocale();
  }

  /// Load the saved locale from SharedPreferences.
  /// If no preference is saved, try to use the system locale.
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);

    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    } else {
      // Try to use system locale if supported
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (_isSupported(systemLocale)) {
        _locale = Locale(systemLocale.languageCode);
      } else {
        _locale = const Locale('en'); // Default to English
      }
    }
    notifyListeners();
  }

  /// Check if a locale is supported
  bool _isSupported(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  /// Change the locale and persist the preference.
  Future<void> setLocale(Locale newLocale) async {
    if (!_isSupported(newLocale)) {
      return;
    }

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }

  /// Reset to system locale
  Future<void> resetLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);

    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (_isSupported(systemLocale)) {
      _locale = Locale(systemLocale.languageCode);
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }

  /// Get the display name for a locale
  String getDisplayName(Locale locale, BuildContext context) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'tr':
        return 'Türkçe';
      default:
        return locale.languageCode;
    }
  }
}
