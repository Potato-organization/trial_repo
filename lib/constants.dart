import 'package:flutter/material.dart';

/// Central place for all magic numbers and shared string keys used across the app.
class AppConstants {
  AppConstants._();

  // ── Background colour used everywhere ──────────────────────────────────────
  static const Color backgroundColor = Color(0xFF0A0E21);
  static const Color surfaceColor = Color(0xFF1D1E33);

  // ── Shake detection ─────────────────────────────────────────────────────────
  /// Default magnitude threshold (m/s²) for a shake to be recognised.
  static const double defaultShakeSensitivity = 11.0;

  /// Minimum magnitude used in the foreground shake listener that is
  /// independent of the user-configurable sensitivity slider.
  static const double foregroundShakeThreshold = 20.0;

  /// Minimum time between consecutive shake triggers.
  static const Duration shakeDebounce = Duration(seconds: 2);

  // ── Clap / noise detection ──────────────────────────────────────────────────
  /// Default dB threshold for clap detection.
  static const double defaultClapSensitivity = 90.0;

  // ── Light trigger ───────────────────────────────────────────────────────────
  /// Lux value above which the environment is considered "light".
  static const double defaultLuxThreshold = 50.0;

  // ── Recording ───────────────────────────────────────────────────────────────
  static const int maxRecordingSeconds = 5;

  /// Maximum number of recordings a free user can have.
  static const int maxFreeRecordings = 5;

  // ── SharedPreferences keys ──────────────────────────────────────────────────
  static const String playlistKey = 'playlist';
  static const String recordingCountKey = 'recording_count';
  static const String currentTrackIndexKey = 'current_track_index';
  static const String alarmIdCounterKey = 'alarm_id_counter';
  static const String alarmsKey = 'alarms';
  static const String soundStatsKey = 'sound_stats';
  static const String recordingNamesKey = 'recording_names';
}
