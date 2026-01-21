// This file defines the LocaleProvider for internationalization.

import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!L10n.all.contains(locale)) return;

    _locale = locale;
    notifyListeners();
  }

  List<Locale> get supportedLocales => L10n.all;
}

class L10n {
  static final all = [
    const Locale('en'),
    const Locale('de'),
  ];
}