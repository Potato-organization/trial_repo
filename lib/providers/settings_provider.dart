import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isPremium = false;
  double _shakeSensitivity = 11.0;
  bool _stealthMode = false;
  bool _isBackgroundTriggersActive = false;

  final String _premiumKey = 'is_premium';
  final String _sensitivityKey = 'shake_sensitivity';
  final String _stealthKey = 'stealth_mode';
  final String _bgTriggersKey = 'bg_triggers_active';

  bool get isPremium => _isPremium;
  double get shakeSensitivity => _shakeSensitivity;
  bool get stealthMode => _stealthMode;
  bool get isBackgroundTriggersActive => _isBackgroundTriggersActive;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    _shakeSensitivity = prefs.getDouble(_sensitivityKey) ?? 11.0;
    _stealthMode = prefs.getBool(_stealthKey) ?? false;
    _isBackgroundTriggersActive = prefs.getBool(_bgTriggersKey) ?? false;
    notifyListeners();
  }

  void setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    notifyListeners();
  }

  void setSensitivity(double value) async {
    _shakeSensitivity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sensitivityKey, value);
    notifyListeners();
  }

  void setStealthMode(bool value) async {
    _stealthMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stealthKey, value);
    notifyListeners();
  }

  void setBackgroundTriggers(bool value) async {
    _isBackgroundTriggersActive = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgTriggersKey, value);
    notifyListeners();
  }
}
