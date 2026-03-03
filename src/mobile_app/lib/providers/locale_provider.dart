import 'package:flutter/material.dart';

/// Manages the app language.
/// Supported locale codes: 'es', 'en', 'fr'
class LocaleProvider with ChangeNotifier {
  String _locale = 'es'; // Default: Spanish

  String get locale => _locale;

  String get languageName {
    switch (_locale) {
      case 'en': return 'English';
      case 'fr': return 'Français';
      default:   return 'Español';
    }
  }

  String get flagEmoji {
    switch (_locale) {
      case 'en': return '🇺🇸';
      case 'fr': return '🇫🇷';
      default:   return '🇪🇸';
    }
  }

  void setLocale(String localeCode) {
    if (_locale == localeCode) return;
    _locale = localeCode;
    notifyListeners();
  }

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'es', 'name': 'Español',  'flag': '🇪🇸'},
    {'code': 'en', 'name': 'English',  'flag': '🇺🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
  ];
}
