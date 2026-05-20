import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/background_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _isPremium = false;
  double _shakeSensitivity = AppConstants.defaultShakeSensitivity;
  bool _stealthMode = false;
  bool _isSlapModeEnabled = false;
  double _slapSensitivity = AppConstants.defaultSlapSensitivity;
  bool _isBackgroundTriggersActive = false;
  double _clapSensitivity = AppConstants.defaultClapSensitivity;
  int _selectedEffectIndex = 0;
  Set<String> _favoriteAssets = {};
  bool _isLoading = true;

  final String _premiumKey = 'is_premium';
  final String _sensitivityKey = 'shake_sensitivity';
  final String _stealthKey = 'stealth_mode';
  final String _slapModeKey = 'slap_mode';
  final String _slapSensitivityKey = 'slap_sensitivity';
  final String _bgTriggersKey = 'bg_triggers_active';
  final String _clapSensitivityKey = 'clap_sensitivity';
  final String _effectIndexKey = 'selected_effect_index';
  final String _favoritesKey = 'favorite_assets';

  bool get isPremium => _isPremium;
  double get shakeSensitivity => _shakeSensitivity;
  bool get stealthMode => _stealthMode;
  bool get isSlapModeEnabled => _isSlapModeEnabled;
  double get slapSensitivity => _slapSensitivity;
  bool get isBackgroundTriggersActive => _isBackgroundTriggersActive;
  double get clapSensitivity => _clapSensitivity;
  int get selectedEffectIndex => _selectedEffectIndex;
  Set<String> get favoriteAssets => _favoriteAssets;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    _shakeSensitivity =
        prefs.getDouble(_sensitivityKey) ??
        AppConstants.defaultShakeSensitivity;
    _stealthMode = prefs.getBool(_stealthKey) ?? false;
    _isSlapModeEnabled = prefs.getBool(_slapModeKey) ?? false;
    _slapSensitivity =
        prefs.getDouble(_slapSensitivityKey) ??
        AppConstants.defaultSlapSensitivity;
    _isBackgroundTriggersActive = prefs.getBool(_bgTriggersKey) ?? false;
    _clapSensitivity =
        prefs.getDouble(_clapSensitivityKey) ??
        AppConstants.defaultClapSensitivity;
    _selectedEffectIndex = prefs.getInt(_effectIndexKey) ?? 0;
    _favoriteAssets = Set<String>.from(
      prefs.getStringList(_favoritesKey) ?? [],
    );
    _isLoading = false;
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

  void setSlapMode(bool value) async {
    _isSlapModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_slapModeKey, value);
    notifyListeners();
  }

  void setSlapSensitivity(double value) async {
    _slapSensitivity = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_slapSensitivityKey, _slapSensitivity);
    notifyListeners();
  }

  void setBackgroundTriggers(bool value) async {
    _isBackgroundTriggersActive = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgTriggersKey, value);
    await BackgroundService.setEnabled(value);
    notifyListeners();
  }

  void setClapSensitivity(double value) async {
    _clapSensitivity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_clapSensitivityKey, value);
    notifyListeners();
  }

  void setSelectedEffectIndex(int index) async {
    _selectedEffectIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_effectIndexKey, index);
    notifyListeners();
  }

  void toggleFavorite(String assetPath) async {
    if (_favoriteAssets.contains(assetPath)) {
      _favoriteAssets.remove(assetPath);
    } else {
      _favoriteAssets.add(assetPath);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteAssets.toList());
    notifyListeners();
  }
}
