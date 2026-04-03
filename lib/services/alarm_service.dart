import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../constants.dart';

class AlarmService {
  /// Single static player reused across alarm callbacks to prevent leaks.
  static AudioPlayer? _player;
  static AudioPlayer get _audioPlayer => _player ??= AudioPlayer();

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  /// Allocates a unique alarm ID using a persisted counter.
  static Future<int> nextAlarmId() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(AppConstants.alarmIdCounterKey) ?? 1000) + 1;
    await prefs.setInt(AppConstants.alarmIdCounterKey, next);
    return next;
  }

  static Future<void> scheduleAlarm(
    int alarmId,
    DateTime time,
    bool repeat,
  ) async {
    if (repeat) {
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        _callback,
        startAt: time,
        exact: true,
        wakeup: true,
      );
    } else {
      await AndroidAlarmManager.oneShotAt(
        time,
        alarmId,
        _callback,
        exact: true,
        wakeup: true,
      );
    }
  }

  static Future<void> cancelAlarm(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
  }

  @pragma('vm:entry-point')
  static void _callback() async {
    debugPrint('Alarm triggered!');
    final prefs = await SharedPreferences.getInstance();
    final playlist = prefs.getStringList(AppConstants.playlistKey) ?? [];

    if (playlist.isNotEmpty) {
      final path = playlist[Random().nextInt(playlist.length)];
      try {
        await _audioPlayer.setFilePath(path);
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error playing alarm: $e');
      }
    }
  }
}

