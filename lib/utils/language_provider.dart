// lib/utils/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  LanguageProvider() {
    _loadLanguage();
  }

  String get currentLanguage => _currentLanguage;

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language_code') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', lang);
      notifyListeners();
    }
  }

  void toggleLanguage() {
    if (_currentLanguage == 'en') {
      setLanguage('si');
    } else if (_currentLanguage == 'si') {
      setLanguage('ta');
    } else {
      setLanguage('en');
    }
  }

  String translate(String key) {
    return Translations.translate(key, _currentLanguage);
  }

  // Helper for flags/names
  String get currentLanguageName {
    switch (_currentLanguage) {
      case 'si':
        return 'Sinhala';
      case 'ta':
        return 'Tamil';
      case 'en':
      default:
        return 'English';
    }
  }
}
