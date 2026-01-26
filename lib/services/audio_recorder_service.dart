import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  static const String _countKey = 'recording_count';
  static const String _prefsKey = 'playlist';

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (await hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_countKey) ?? 0;
      final newCount = currentCount + 1;
      
      final String filePath = p.join(
        directory.path,
        'shake_$newCount.m4a',
      );
      
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
    }
  }

  Future<String?> stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      // Update count and sync playlist
      await _syncPlaylist();
    }
    return path;
  }

  Future<void> _syncPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    
    final paths = files
        .where((file) => file.path.contains('shake_') && file.path.endsWith('.m4a'))
        .map((file) => file.path)
        .toList()
      ..sort((a, b) {
        // Sort by number: shake_1.m4a, shake_2.m4a, etc.
        final numA = int.tryParse(p.basename(a).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB = int.tryParse(p.basename(b).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });
    
    await prefs.setStringList(_prefsKey, paths);
    await prefs.setInt(_countKey, paths.length);
  }

  Future<List<String>> getRecordings() async {
    await _syncPlaylist(); // Always sync on load
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? [];
  }
  
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await _syncPlaylist();
  }
  
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    
    for (var file in files) {
      if (file.path.contains('shake_') && file.path.endsWith('.m4a')) {
        await File(file.path).delete();
      }
    }
    
    await prefs.setStringList(_prefsKey, []);
    await prefs.setInt(_countKey, 0);
  }
}
