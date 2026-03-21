import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

class BackgroundService {
  static const String _prefsKey = 'playlist';
  static const String _countKey = 'recording_count';
  static const String _indexKey = 'current_track_index';
  
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'chaos_foreground',
        initialNotificationTitle: 'Chaos',
        initialNotificationContent: 'Shake to play sounds',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    final AudioPlayer player = AudioPlayer();
    
    DateTime? lastShakeTime;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentIndex = prefs.getInt(_indexKey) ?? 0;
    
    debugPrint("BackgroundService started");
    
    service.on('updatePlaylist').listen((event) async {
      await prefs.reload();
      currentIndex = 0;
      await prefs.setInt(_indexKey, 0);
    });
    
    service.on('clearPlaylist').listen((event) async {
      await prefs.reload();
      currentIndex = 0;
      await prefs.setInt(_indexKey, 0);
    });

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    accelerometerEventStream().listen((AccelerometerEvent event) async {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Sensitivity check from settings
      await prefs.reload();
      double sensitivity = prefs.getDouble('shake_sensitivity') ?? 11.0;

      if (magnitude > sensitivity) {
        final now = DateTime.now();
        
        if (lastShakeTime == null || now.difference(lastShakeTime!) > const Duration(seconds: 2)) {
          lastShakeTime = now;
          
          final playlist = prefs.getStringList(_prefsKey) ?? [];
          final count = playlist.length;
          
          if (count > 0) {
            if (currentIndex >= count) currentIndex = 0;
            
            final path = playlist[currentIndex];
            
            try {
              await player.setFilePath(path);
              await player.play();
              
              currentIndex = (currentIndex + 1) % count;
              await prefs.setInt(_indexKey, currentIndex);
            } catch (e) {
              debugPrint("❌ Background playback error: $e");
            }
          }
        }
      }
    });
  }
}
