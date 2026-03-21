import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  // Effects state
  double _pitch = 1.0;
  double _speed = 1.0;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> play(String path, {double pitch = 1.0, double speed = 1.0}) async {
    _pitch = pitch;
    _speed = speed;

    final prefs = await SharedPreferences.getInstance();
    final stealthMode = prefs.getBool('stealth_mode') ?? false;

    try {
      if (stealthMode) {
        await _player.setVolume(1.0); // Set volume to max even if system volume is low
      }
      await _player.setFilePath(path);
      await _player.setPitch(_pitch);
      await _player.setSpeed(_speed);
      await _player.play();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> playAsset(String assetPath, {double pitch = 1.0, double speed = 1.0}) async {
    try {
      await _player.setAsset(assetPath);
      await _player.setPitch(pitch);
      await _player.setSpeed(speed);
      await _player.play();
    } catch (e) {
      print("Error playing asset: $e");
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
