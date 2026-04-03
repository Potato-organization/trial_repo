import 'package:flutter/material.dart';

class ChaosAlarm {
  final String id;

  /// Integer ID used by AndroidAlarmManager. Derived from an incrementing
  /// counter stored in SharedPreferences so each alarm gets a unique slot.
  final int androidAlarmId;

  final TimeOfDay time;
  final bool isEnabled;
  final List<int> days; // 0=Mon, 6=Sun
  final String? soundPath;
  final String? assetPath;
  final bool isRandom;

  const ChaosAlarm({
    required this.id,
    required this.androidAlarmId,
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
      androidAlarmId: androidAlarmId,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      days: days ?? this.days,
      soundPath: soundPath ?? this.soundPath,
      assetPath: assetPath ?? this.assetPath,
      isRandom: isRandom ?? this.isRandom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'androidAlarmId': androidAlarmId,
        'hour': time.hour,
        'minute': time.minute,
        'isEnabled': isEnabled,
        'days': days,
        'soundPath': soundPath,
        'assetPath': assetPath,
        'isRandom': isRandom,
      };

  factory ChaosAlarm.fromJson(Map<String, dynamic> json) => ChaosAlarm(
        id: json['id'] as String,
        androidAlarmId: (json['androidAlarmId'] as num?)?.toInt() ?? 1001,
        time: TimeOfDay(
          hour: (json['hour'] as num).toInt(),
          minute: (json['minute'] as num).toInt(),
        ),
        isEnabled: json['isEnabled'] as bool? ?? true,
        days: (json['days'] as List<dynamic>? ?? [0, 1, 2, 3, 4, 5, 6])
            .map((e) => (e as num).toInt())
            .toList(),
        soundPath: json['soundPath'] as String?,
        assetPath: json['assetPath'] as String?,
        isRandom: json['isRandom'] as bool? ?? false,
      );
}
