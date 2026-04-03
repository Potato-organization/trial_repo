import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NeonTheme { blue, green, pink }

class ThemeProvider with ChangeNotifier {
  NeonTheme _currentTheme = NeonTheme.blue;
  bool _isLoading = true;
  final String _themeKey = 'neon_theme_accent';

  NeonTheme get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _currentTheme = NeonTheme.values[themeIndex];
    _isLoading = false;
    notifyListeners();
  }

  void setTheme(NeonTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  Color get accentColor {
    switch (_currentTheme) {
      case NeonTheme.blue:
        return Colors.blueAccent;
      case NeonTheme.green:
        return Colors.greenAccent;
      case NeonTheme.pink:
        return Colors.pinkAccent;
    }
  }

  ThemeData getThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0A0E21),
      scaffoldBackgroundColor: const Color(0xFF0A0E21),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: const Color(0xFF1D1E33),
      ),
    );
  }
}
