import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class AlarmService {
  static const int _alarmId = 1001;

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleAlarm(DateTime time, bool repeat) async {
    if (repeat) {
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        _alarmId,
        callback,
        startAt: time,
        exact: true,
        wakeup: true,
      );
    } else {
      await AndroidAlarmManager.oneShotAt(
        time,
        _alarmId,
        callback,
        exact: true,
        wakeup: true,
      );
    }
  }

  static Future<void> cancelAlarm() async {
    await AndroidAlarmManager.cancel(_alarmId);
  }

  @pragma('vm:entry-point')
  static void callback() async {
    print('Alarm triggered!');
    final player = AudioPlayer();
    final prefs = await SharedPreferences.getInstance();
    final playlist = prefs.getStringList('playlist') ?? [];

    if (playlist.isNotEmpty) {
      // Play a random sound from custom recordings
      final random = Random();
      final path = playlist[random.nextInt(playlist.length)];
      try {
        await player.setFilePath(path);
        await player.setVolume(1.0);
        await player.play();
      } catch (e) {
        print('Error playing alarm: $e');
      }
    }
  }
}
