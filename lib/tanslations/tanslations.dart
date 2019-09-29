import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'locale_util.dart';

/// Class for Translate
///
/// For example:
///
/// import 'package:workout/translations.dart';
///
/// ```dart
/// For TextField content
/// Translations.of(context).text("home_page_title");
/// ```
///
/// ```dart
/// For speak string
/// Note: Tts will speak english if currentLanguage[# Tts's parameter] can't support
///
/// Translations.of(context).speakText("home_page_title");
/// ```
///
/// "home_page_title" is the key for text value
///
class Translations {
  Translations(Locale locale) {
    this.locale = locale;
    _localizedValues = null;
  }

  Locale locale;
  static Map<dynamic, dynamic> _localizedValues;
  static Map<dynamic, dynamic> _localizedValuesEn; // English map

  static Translations of(BuildContext context) {
    return Localizations.of<Translations>(context, Translations);
  }

  String text(String key, [String replacementWord]) {
    var res = '';
    try {
      String value = _localizedValues[key];
      if (value == null || value.isEmpty) {
        res = englishText(key);
      } else {
        res = value;
      }
    } catch (e) {
      res = englishText(key);
    }
    return replacementWord != null
        ? res.replaceAll('{n}', replacementWord)
        : res;
  }

  String englishText(String key) {
    return _localizedValuesEn[key] ?? '** $key not found';
  }

  static Future<Translations> load(Locale locale) async {
    Translations translations = Translations(locale);
    print('localization/i18n_zh_36.json');
    String enJsonContent =
        await rootBundle.loadString("localization/i18n_zh_36.json");
    _localizedValuesEn = json.decode(enJsonContent);
    _localizedValues = json.decode(enJsonContent);
    return translations;
  }

  get currentLanguage => locale.languageCode;
}

class TranslationsDelegate extends LocalizationsDelegate<Translations> {
  const TranslationsDelegate();

  // Support languages
  @override
  bool isSupported(Locale locale) {
    // Reset tts language
    localeUtil.languageCode = locale.languageCode;
    return localeUtil.supportedLanguages.contains(locale.languageCode);
  }

  @override
  Future<Translations> load(Locale locale) => Translations.load(locale);

  @override
  bool shouldReload(TranslationsDelegate old) => true;
}

// Delegate strong init a Translations instance when language was changed
class SpecificLocalizationDelegate extends LocalizationsDelegate<Translations> {
  final Locale overriddenLocale;

  const SpecificLocalizationDelegate(this.overriddenLocale);

  @override
  bool isSupported(Locale locale) => overriddenLocale != null;

  @override
  Future<Translations> load(Locale locale) =>
      Translations.load(overriddenLocale);

  @override
  bool shouldReload(LocalizationsDelegate<Translations> old) => true;
}
