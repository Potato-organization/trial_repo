import 'package:noise_meter/noise_meter.dart';
import 'package:light/light.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class TriggerService {
  static NoiseMeter _noiseMeter = NoiseMeter();
  static StreamSubscription<NoiseReading>? _noiseSubscription;

  static Light _light = Light();
  static StreamSubscription<int>? _lightSubscription;

  static bool _isClapDetectionActive = false;
  static bool _isLightTriggerActive = false;

  static final AudioPlayer _player = AudioPlayer();

  static void toggleClapDetection(bool active) {
    _isClapDetectionActive = active;
    if (active) {
      _noiseSubscription = _noiseMeter.noise.listen((NoiseReading reading) {
        // High decibel reading = possible clap
        if (reading.maxDecibel > 90) {
          _triggerChaos();
        }
      });
    } else {
      _noiseSubscription?.cancel();
    }
  }

  static Future<void> _triggerChaos() async {
    final prefs = await SharedPreferences.getInstance();
    final playlist = prefs.getStringList('playlist') ?? [];
    if (playlist.isNotEmpty) {
      final random = Random();
      final path = playlist[random.nextInt(playlist.length)];
      try {
        await _player.setFilePath(path);
        await _player.play();
      } catch (e) {
        print('Error triggering trigger: $e');
      }
    }
  }

  static void toggleLightTrigger(bool active) {
    _isLightTriggerActive = active;
    if (active) {
      _lightSubscription = _light.lightSensorStream.listen((int lux) {
        // Dark to light transition (> 50 lux)
        if (lux > 50) {
          _triggerChaos();
        }
      });
    } else {
      _lightSubscription?.cancel();
    }
  }

  static void dispose() {
    _noiseSubscription?.cancel();
    _lightSubscription?.cancel();
  }
}
