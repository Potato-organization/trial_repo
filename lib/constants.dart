import 'package:flutter/material.dart';
import 'ui/chaos_design.dart';

/// Central place for all magic numbers and shared string keys used across the app.
class AppConstants {
  AppConstants._();

  // ── Background colour used everywhere ──────────────────────────────────────
  static const Color backgroundColor = ChaosColors.background;
  static const Color surfaceColor = ChaosColors.panel;

  // ── Shake detection ─────────────────────────────────────────────────────────
  /// Default magnitude threshold (m/s²) for a shake to be recognised.
  static const double defaultShakeSensitivity = 11.0;

  /// Minimum magnitude used in the foreground shake listener that is
  /// independent of the user-configurable sensitivity slider.
  static const double foregroundShakeThreshold = 20.0;

  /// Minimum time between consecutive shake triggers.
  static const Duration shakeDebounce = Duration(seconds: 2);

  // ── Slap detection ─────────────────────────────────────────────────────────
  /// Strong impact threshold used for slap-style phone taps.
  static const double defaultSlapImpactThreshold = 22.0;

  /// Minimum magnitude jump between samples before an impact counts as a slap.
  static const double defaultSlapJerkThreshold = 10.0;

  /// User-facing slap sensitivity. 0 is firm taps only, 1 is very responsive.
  static const double defaultSlapSensitivity = 0.55;

  /// Minimum time between consecutive slap triggers.
  static const Duration slapDebounce = Duration(milliseconds: 700);

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
