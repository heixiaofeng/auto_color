import 'package:flutter/material.dart';

typedef void LocaleChangeCallback(Locale locale);

class LocaleUtil {
  // Support languages list
  final List<String> supportedLanguages = [
    'zh',
  ];
  // Support Locales list

  Iterable<Locale> supportedLocales() =>
      supportedLanguages.map<Locale>((lang) => Locale(lang, ''));
  //=> supportedLanguages.map<Locale>((lang) => Locale(lang, ''));

  // Callback for manual locale changed
  LocaleChangeCallback onLocaleChanged;

  Locale locale;
  String languageCode;

  static final LocaleUtil _localeUtil = LocaleUtil._internal();

  factory LocaleUtil() {
    return _localeUtil;
  }

  LocaleUtil._internal();

  /// 获取当前系统语言
  String getLanguageCode() {
    if (languageCode == null) {
      return "zh";
    }
    return languageCode;
  }
}

LocaleUtil localeUtil = LocaleUtil();
