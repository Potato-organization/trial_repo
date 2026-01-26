import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _sensorSub;

  bool _isShaking = false;
  DateTime _lastShake = DateTime.now();

  static const double shakeThreshold = 15.0;
  static const int stopDelayMs = 500;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _sensorSub = accelerometerEvents.listen((event) {
      double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (magnitude > shakeThreshold) {
        _lastShake = DateTime.now();
        if (!_isShaking) {
          _startSound();
        }
      }

      if (_isShaking &&
          DateTime.now().difference(_lastShake).inMilliseconds > stopDelayMs) {
        _stopSound();
      }
    });
  }

  Future<void> _startSound() async {
    _isShaking = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/shake.mp3'));
  }

  Future<void> _stopSound() async {
    _isShaking = false;
    await _player.stop();
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shake Detector")),
      body: Center(
        child: Text(
          _isShaking ? "SHAKING 🔊" : "Not shaking",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
