import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Tracks how many times each sound (identified by its path or asset name)
/// has been played. Data is persisted in SharedPreferences as JSON.
class StatisticsService {
  StatisticsService._();

  static Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.soundStatsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// Record a single play event for the given [soundIdentifier].
  static Future<void> recordPlay(String soundIdentifier) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await getStats();
    stats[soundIdentifier] = (stats[soundIdentifier] ?? 0) + 1;
    await prefs.setString(AppConstants.soundStatsKey, jsonEncode(stats));
  }

  static Future<void> clearStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.soundStatsKey);
  }

  /// Returns a sorted list of (soundId, playCount) pairs, highest first.
  static Future<List<MapEntry<String, int>>> getTopSounds({int limit = 50}) async {
    final stats = await getStats();
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}
