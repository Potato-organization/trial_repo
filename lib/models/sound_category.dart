import 'package:flutter/material.dart';

class SoundCategory {
  final String title;
  final String icon;
  final List<PreloadedSound> sounds;

  const SoundCategory({
    required this.title,
    required this.icon,
    required this.sounds,
  });

  static const List<SoundCategory> categories = [
    SoundCategory(
      title: 'Classic Memes',
      icon: '🤣',
      sounds: [
        PreloadedSound(name: 'Bruh', assetPath: 'assets/sounds/memes/bruh.mp3'),
        PreloadedSound(name: 'Oh No', assetPath: 'assets/sounds/memes/oh_no.mp3'),
        PreloadedSound(name: 'Airhorn', assetPath: 'assets/sounds/memes/airhorn.mp3'),
      ],
    ),
    SoundCategory(
      title: 'Animal Chaos',
      icon: '🦁',
      sounds: [
        PreloadedSound(name: 'Chicken', assetPath: 'assets/sounds/animals/chicken.mp3'),
        PreloadedSound(name: 'Goat Scream', assetPath: 'assets/sounds/animals/goat.mp3'),
        PreloadedSound(name: 'Cat Mew', assetPath: 'assets/sounds/animals/cat.mp3'),
      ],
    ),
    SoundCategory(
      title: 'Human Noises',
      icon: '👤',
      sounds: [
        PreloadedSound(name: 'Fart', assetPath: 'assets/sounds/human/fart.mp3'),
        PreloadedSound(name: 'Snore', assetPath: 'assets/sounds/human/snore.mp3'),
        PreloadedSound(name: 'Burp', assetPath: 'assets/sounds/human/burp.mp3'),
      ],
    ),
  ];
}

class PreloadedSound {
  final String name;
  final String assetPath;

  const PreloadedSound({
    required this.name,
    required this.assetPath,
  });
}
