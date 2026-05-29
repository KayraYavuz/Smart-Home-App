import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yavuz_lock/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageProvider', () {
    test('defaults to English when no preference saved', () async {
      final provider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.locale.languageCode, 'en');
    });

    test('setLocale changes locale to Turkish', () async {
      final provider = LanguageProvider();
      await provider.setLocale(const Locale('tr'));
      expect(provider.locale.languageCode, 'tr');
    });

    test('setLocale changes locale to German', () async {
      final provider = LanguageProvider();
      await provider.setLocale(const Locale('de'));
      expect(provider.locale.languageCode, 'de');
    });

    test('setLocale persists to SharedPreferences', () async {
      final provider = LanguageProvider();
      await provider.setLocale(const Locale('tr'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'tr');
    });

    test('unsupported locale is rejected', () async {
      final provider = LanguageProvider();
      final before = provider.locale.languageCode;
      await provider.setLocale(const Locale('fr'));
      expect(provider.locale.languageCode, before);
    });

    test('resetLocale removes saved preference', () async {
      final provider = LanguageProvider();
      await provider.setLocale(const Locale('de'));
      await provider.resetLocale();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), isNull);
    });

    test('supportedLocales contains en, tr, de', () {
      expect(
        LanguageProvider.supportedLocales.map((l) => l.languageCode).toList(),
        containsAll(['en', 'tr', 'de']),
      );
    });

    test('notifies listeners on locale change', () async {
      final provider = LanguageProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.setLocale(const Locale('de'));
      expect(notifyCount, greaterThan(0));
    });
  });
}
