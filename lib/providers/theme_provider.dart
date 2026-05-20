import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/chaos_design.dart';

enum AppTheme { blue, green, coral }

class ThemeProvider with ChangeNotifier {
  AppTheme _currentTheme = AppTheme.blue;
  bool _isLoading = true;
  final String _themeKey = 'app_theme_accent';
  final String _legacyThemeKey = 'neon_theme_accent';

  AppTheme get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex =
        prefs.getInt(_themeKey) ?? prefs.getInt(_legacyThemeKey) ?? 0;
    final safeIndex = themeIndex >= 0 && themeIndex < AppTheme.values.length
        ? themeIndex
        : 0;
    _currentTheme = AppTheme.values[safeIndex];
    if (!prefs.containsKey(_themeKey)) {
      await prefs.setInt(_themeKey, safeIndex);
    }
    _isLoading = false;
    notifyListeners();
  }

  void setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  Color get accentColor {
    switch (_currentTheme) {
      case AppTheme.blue:
        return ChaosColors.blue;
      case AppTheme.green:
        return ChaosColors.green;
      case AppTheme.coral:
        return ChaosColors.coral;
    }
  }

  ThemeData getThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ChaosColors.background,
      scaffoldBackgroundColor: ChaosColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: ChaosColors.panel,
        onSurface: ChaosColors.text,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      dividerColor: ChaosColors.border,
    );
  }
}
