import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> en;
  late Map<String, dynamic> tr;
  late Map<String, dynamic> de;

  setUpAll(() {
    en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    tr = jsonDecode(File('lib/l10n/app_tr.arb').readAsStringSync())
        as Map<String, dynamic>;
    de = jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync())
        as Map<String, dynamic>;
  });

  Set<String> keys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  group('L10n key completeness', () {
    test('TR has all EN keys', () {
      final missing = keys(en).difference(keys(tr));
      expect(missing, isEmpty,
          reason: 'TR is missing keys: $missing');
    });

    test('DE has all EN keys', () {
      final missing = keys(en).difference(keys(de));
      expect(missing, isEmpty,
          reason: 'DE is missing keys: $missing');
    });

    test('EN has all TR keys', () {
      final extra = keys(tr).difference(keys(en));
      expect(extra, isEmpty,
          reason: 'TR has extra keys not in EN: $extra');
    });

    test('EN has all DE keys', () {
      final extra = keys(de).difference(keys(en));
      expect(extra, isEmpty,
          reason: 'DE has extra keys not in EN: $extra');
    });

    test('no placeholder mismatch in TR', () {
      final issues = <String>[];
      final ph = RegExp(r'\{(\w+)\}');
      for (final key in keys(en)) {
        final enVal = en[key]?.toString() ?? '';
        final trVal = tr[key]?.toString() ?? '';
        final enPh = ph.allMatches(enVal).map((m) => m.group(1)).toSet();
        final trPh = ph.allMatches(trVal).map((m) => m.group(1)).toSet();
        if (enPh.difference(trPh).isNotEmpty || trPh.difference(enPh).isNotEmpty) {
          issues.add('$key: EN=$enPh TR=$trPh');
        }
      }
      expect(issues, isEmpty,
          reason: 'Placeholder mismatches in TR:\n${issues.join('\n')}');
    });

    test('no placeholder mismatch in DE', () {
      final issues = <String>[];
      final ph = RegExp(r'\{(\w+)\}');
      for (final key in keys(en)) {
        final enVal = en[key]?.toString() ?? '';
        final deVal = de[key]?.toString() ?? '';
        final enPh = ph.allMatches(enVal).map((m) => m.group(1)).toSet();
        final dePh = ph.allMatches(deVal).map((m) => m.group(1)).toSet();
        if (enPh.difference(dePh).isNotEmpty || dePh.difference(enPh).isNotEmpty) {
          issues.add('$key: EN=$enPh DE=$dePh');
        }
      }
      expect(issues, isEmpty,
          reason: 'Placeholder mismatches in DE:\n${issues.join('\n')}');
    });

    test('no empty values in EN', () {
      final empty = keys(en).where((k) => (en[k] ?? '').toString().isEmpty);
      expect(empty, isEmpty, reason: 'EN has empty values: $empty');
    });

    test('no empty values in TR', () {
      final empty = keys(tr).where((k) => (tr[k] ?? '').toString().isEmpty);
      expect(empty, isEmpty, reason: 'TR has empty values: $empty');
    });

    test('no empty values in DE', () {
      final empty = keys(de).where((k) => (de[k] ?? '').toString().isEmpty);
      expect(empty, isEmpty, reason: 'DE has empty values: $empty');
    });
  });
}
