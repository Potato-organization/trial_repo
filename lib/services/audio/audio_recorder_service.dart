import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _autoStopTimer;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Starts recording and automatically stops after [AppConstants.maxRecordingSeconds].
  /// [onAutoStop] is called with the recorded file path when the limit is reached.
  Future<void> startRecording({void Function(String? path)? onAutoStop}) async {
    if (await hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(AppConstants.recordingCountKey) ?? 0;
      final newCount = currentCount + 1;

      final String filePath = p.join(
        directory.path,
        'shake_$newCount.m4a',
      );

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      // Enforce the maximum recording length at the service level.
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(
        const Duration(seconds: AppConstants.maxRecordingSeconds),
        () async {
          final path = await stopRecording();
          onAutoStop?.call(path);
        },
      );
    }
  }

  Future<String?> stopRecording() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    final path = await _audioRecorder.stop();
    if (path != null) {
      await _syncPlaylist();
    }
    return path;
  }

  Future<void> _syncPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();

    if (!await directory.exists()) return;

    final List<FileSystemEntity> files = directory.listSync();

    final paths = files
        .where((file) =>
            file.path.contains('shake_') && file.path.endsWith('.m4a'))
        .map((file) => file.path)
        .toList()
      ..sort((a, b) {
        final numA =
            int.tryParse(p.basename(a).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB =
            int.tryParse(p.basename(b).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

    await prefs.setStringList(AppConstants.playlistKey, paths);
    await prefs.setInt(AppConstants.recordingCountKey, paths.length);
  }

  Future<List<String>> getRecordings() async {
    await _syncPlaylist();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.playlistKey) ?? [];
  }

  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    // Remove custom name entry.
    final names = await getRecordingNames();
    names.remove(path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.recordingNamesKey, jsonEncode(names));
    await _syncPlaylist();
  }

  Future<void> clearAll() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();

    for (var file in files) {
      if (file.path.contains('shake_') && file.path.endsWith('.m4a')) {
        await File(file.path).delete();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.playlistKey, []);
    await prefs.setInt(AppConstants.recordingCountKey, 0);
    await prefs.remove(AppConstants.recordingNamesKey);
  }

  Future<void> reorderRecordings(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.playlistKey, newOrder);
  }

  // ── Custom names ────────────────────────────────────────────────────────────

  Future<Map<String, String>> getRecordingNames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.recordingNamesKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> setRecordingName(String path, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final names = await getRecordingNames();
    if (name.trim().isEmpty) {
      names.remove(path);
    } else {
      names[path] = name.trim();
    }
    await prefs.setString(AppConstants.recordingNamesKey, jsonEncode(names));
  }
}
