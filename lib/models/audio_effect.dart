import 'package:flutter/material.dart';

class AudioEffect {
  final String name;
  final double pitch;
  final double speed;
  final IconData icon;

  const AudioEffect({
    required this.name,
    required this.pitch,
    required this.speed,
    required this.icon,
  });

  static const List<AudioEffect> presets = [
    AudioEffect(name: 'Natural', pitch: 1.0, speed: 1.0, icon: Icons.person_rounded),
    AudioEffect(name: 'Chipmunk', pitch: 1.6, speed: 1.1, icon: Icons.emoji_emotions_rounded),
    AudioEffect(name: 'Robot', pitch: 0.6, speed: 0.8, icon: Icons.smart_toy_rounded),
    AudioEffect(name: 'Deep Voice', pitch: 0.5, speed: 0.9, icon: Icons.record_voice_over_rounded),
    AudioEffect(name: 'Fast Forward', pitch: 1.2, speed: 1.8, icon: Icons.fast_forward_rounded),
    AudioEffect(name: 'Slow Motion', pitch: 0.8, speed: 0.5, icon: Icons.slow_motion_video_rounded),
  ];
}
