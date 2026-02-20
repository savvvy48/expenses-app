import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';
  static const String _currencyKey = 'currency_code';
  
  late Box _box;
  
  // Default values
  ThemeMode _themeMode = ThemeMode.dark;
  String _currencyCode = 'USD';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currencyCode => _currencyCode;
  
  String get currencySymbol => getSymbolForCode(_currencyCode);

  static String getSymbolForCode(String code) {
    switch (code) {
      case 'INR': return '₹';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'CAD': return 'C\$';
      case 'AUD': return 'A\$';
      default: return '\$';
    }
  }

  SettingsProvider() {
    _box = Hive.box(_boxName);
    _loadSettings();
  }

  void _loadSettings() {
    // Load Theme
    final isDark = _box.get(_themeKey, defaultValue: true);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Currency
    _currencyCode = _box.get(_currencyKey, defaultValue: 'USD');
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _box.put(_themeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _box.put(_themeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    await _box.put(_currencyKey, code);
    notifyListeners();
  }
}
