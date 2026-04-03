import 'package:flutter/services.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:light/light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../constants.dart';
import 'statistics_service.dart';

class TriggerService {
  static final NoiseMeter _noiseMeter = NoiseMeter();
  static StreamSubscription<NoiseReading>? _noiseSubscription;

  static final Light _light = Light();
  static StreamSubscription<int>? _lightSubscription;

  static bool _isClapDetectionActive = false;
  static bool _isLightTriggerActive = false;

  /// Previous light state used to detect dark→light transition.
  static bool _wasLight = false;

  static final AudioPlayer _player = AudioPlayer();

  // ── Clap detection ──────────────────────────────────────────────────────────

  /// Returns [true] if microphone permission was granted.
  static Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Starts or stops clap detection.
  /// [sensitivity] is the dB threshold (default [AppConstants.defaultClapSensitivity]).
  static Future<bool> toggleClapDetection(
    bool active, {
    double sensitivity = AppConstants.defaultClapSensitivity,
  }) async {
    _isClapDetectionActive = active;
    if (active) {
      if (!await _ensureMicPermission()) return false;
      _noiseSubscription = _noiseMeter.noise.listen((NoiseReading reading) {
        if (reading.maxDecibel > sensitivity) {
          _triggerChaos('clap');
        }
      });
      return true;
    } else {
      await _noiseSubscription?.cancel();
      _noiseSubscription = null;
      return true;
    }
  }

  // ── Light trigger ───────────────────────────────────────────────────────────

  static Future<void> toggleLightTrigger(bool active) async {
    _isLightTriggerActive = active;
    if (active) {
      // Initialise with current lighting so the first read doesn't false-fire.
      _wasLight = false;
      _lightSubscription = _light.lightSensorStream.listen((int lux) {
        final isLight = lux > AppConstants.defaultLuxThreshold;
        if (isLight && !_wasLight) {
          // Transition: dark → light
          _triggerChaos('light');
        }
        _wasLight = isLight;
      });
    } else {
      await _lightSubscription?.cancel();
      _lightSubscription = null;
    }
  }

  // ── Shared chaos trigger ────────────────────────────────────────────────────

  static Future<void> _triggerChaos(String source) async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    final playlist = prefs.getStringList(AppConstants.playlistKey) ?? [];
    if (playlist.isNotEmpty) {
      final path = playlist[Random().nextInt(playlist.length)];
      try {
        await _player.setFilePath(path);
        await _player.play();
        await StatisticsService.recordPlay(path);
      } catch (e) {
        debugPrint('TriggerService [$source] playback error: $e');
      }
    }
  }

  static Future<void> dispose() async {
    await _noiseSubscription?.cancel();
    await _lightSubscription?.cancel();
    _noiseSubscription = null;
    _lightSubscription = null;
  }
}

