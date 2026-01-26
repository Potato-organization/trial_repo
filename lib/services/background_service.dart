import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class BackgroundService {
  static const String _prefsKey = 'playlist';
  static const String _countKey = 'recording_count';
  static const String _indexKey = 'current_track_index';
  
  // 2.7g in m/s² (g ≈ 9.8 m/s²)
  static const double shakeThreshold = 26.5;
  
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
    
    // Player setup
    final AudioPlayer player = AudioPlayer();
    
    // Configured audio to play through speaker at max volume
    await player.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.defaultToSpeaker,
        },
      ),
    ));
    
    // State
    DateTime? lastShakeTime;
    bool isPlaying = false;
    
    // Load initial index from prefs
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentIndex = prefs.getInt(_indexKey) ?? 0;
    
    debugPrint(" BackgroundService started");
    
    // Listen for UI updates
    service.on('updatePlaylist').listen((event) async {
      await prefs.reload();
      currentIndex = 0; // Reset on playlist update
      await prefs.setInt(_indexKey, 0);
      final count = prefs.getInt(_countKey) ?? 0;
      debugPrint(" Playlist updated: $count tracks");
    });
    
    service.on('clearPlaylist').listen((event) async {
      await prefs.reload();
      currentIndex = 0;
      await prefs.setInt(_indexKey, 0);
      debugPrint(" Playlist cleared");
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

    // Shake Detection - using accelerometerEventStream (includes gravity, like working code)
    accelerometerEventStream().listen((AccelerometerEvent event) async {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Threshold 11.0 (very sensitive - slight shake triggers)
      if (magnitude > 11.0) {
        final now = DateTime.now();
        
        // Debounce: 2 seconds between shakes
        if (lastShakeTime == null || now.difference(lastShakeTime!) > const Duration(seconds: 2)) {
          lastShakeTime = now;
          
          // Reload prefs to get latest playlist (in case app was killed)
          await prefs.reload();
          final playlist = prefs.getStringList(_prefsKey) ?? [];
          final count = playlist.length;
          
          debugPrint(" SHAKE! Magnitude: ${magnitude.toStringAsFixed(1)} m/s²");
          
          if (count > 0) {
            // Ensure index is valid
            if (currentIndex >= count) {
              currentIndex = 0;
            }
            
            final path = playlist[currentIndex];
            debugPrint("▶ Playing: Sound ${currentIndex + 1} of $count");
            
            try {
              if (isPlaying) await player.stop();
              await player.play(DeviceFileSource(path));
              isPlaying = true;
              
              // Increment and wrap index
              currentIndex = (currentIndex + 1) % count;
              await prefs.setInt(_indexKey, currentIndex);
              
              debugPrint("✅ Next will be: Sound ${currentIndex + 1}");
            } catch (e) {
              debugPrint("❌ Playback error: $e");
            }
          } else {
            debugPrint("⚠️ No recordings available");
          }
        }
      }
    });
    
    player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
    });
  }
}
