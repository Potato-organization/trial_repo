import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> play(String filePath) async {
    await _audioPlayer.stop(); // Stop any currently playing audio
    await _audioPlayer.play(DeviceFileSource(filePath));
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.onPlayerStateChanged;
  
  void dispose() {
    _audioPlayer.dispose();
  }
}
