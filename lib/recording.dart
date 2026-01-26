import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class VoiceRecorderShake extends StatefulWidget {
  const VoiceRecorderShake({Key? key}) : super(key: key);

  @override
  _VoiceRecorderShakeState createState() => _VoiceRecorderShakeState();
}

class _VoiceRecorderShakeState extends State<VoiceRecorderShake> {
  FlutterSoundRecorder? _recorder;
  AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordedFilePath;
  bool _isRecording = false;

  // Shake detection variables
  static const double shakeThreshold = 15.0;
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  int _lastShakeTime = 0;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    _listenShake();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
    // On iOS, permission will be requested automatically
    // On Android, add RECORD_AUDIO permission in AndroidManifest.xml
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    String path =
        '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
      _recordedFilePath = path;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  void _listenShake() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      double dx = event.x - _lastX;
      double dy = event.y - _lastY;
      double dz = event.z - _lastZ;

      double delta = sqrt(dx * dx + dy * dy + dz * dz);

      int now = DateTime.now().millisecondsSinceEpoch;
      if (delta > shakeThreshold && (now - _lastShakeTime > 500)) {
        _lastShakeTime = now;
        _playRecording(); // Play recording on shake
      }

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            Text(
              _recordedFilePath != null
                  ? 'Recorded file ready. Shake device to play.'
                  : 'No recording yet',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
