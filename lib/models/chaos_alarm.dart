import 'package:flutter/material.dart';

class ChaosAlarm {
  final String id;
  final TimeOfDay time;
  final bool isEnabled;
  final List<int> days; // 0=Mon, 6=Sun
  final String? soundPath;
  final String? assetPath;
  final bool isRandom;

  const ChaosAlarm({
    required this.id,
    required this.time,
    this.isEnabled = true,
    this.days = const [0, 1, 2, 3, 4, 5, 6],
    this.soundPath,
    this.assetPath,
    this.isRandom = false,
  });

  ChaosAlarm copyWith({
    TimeOfDay? time,
    bool? isEnabled,
    List<int>? days,
    String? soundPath,
    String? assetPath,
    bool? isRandom,
  }) {
    return ChaosAlarm(
      id: id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      days: days ?? this.days,
      soundPath: soundPath ?? this.soundPath,
      assetPath: assetPath ?? this.assetPath,
      isRandom: isRandom ?? this.isRandom,
    );
  }
}
