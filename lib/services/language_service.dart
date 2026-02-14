import 'package:flutter/material.dart';

class LanguageService with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      _locale = const Locale('am');
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }
}
