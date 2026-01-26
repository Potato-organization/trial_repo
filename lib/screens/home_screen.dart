import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final AudioPlayerService _playerService = AudioPlayerService();
  
  List<String> _recordings = [];
  bool _isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  
  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  
  // Shake detection
  StreamSubscription? _shakeSubscription;
  DateTime _lastShakeTime = DateTime.now();
  int _currentShakeIndex = 0;
  bool _isShakePlaying = false;
  final AudioPlayer _shakePlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadRecordings();
    _setupShakeDetection();
    
    _playerService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _currentlyPlayingPath = null;
          }
        });
      }
    });
    
    _shakePlayer.onPlayerStateChanged.listen((state) {
      _isShakePlaying = state == PlayerState.playing;
    });
  }
  
  void _setupShakeDetection() {
    _shakeSubscription = accelerometerEventStream().listen((event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Threshold 11.0 - very sensitive
      if (magnitude > 11.0) {
        final now = DateTime.now();
        
        // Debounce 2 seconds
        if (now.difference(_lastShakeTime) > const Duration(seconds: 2)) {
          _lastShakeTime = now;
          _onShakeDetected();
        }
      }
    });
  }
  
  Future<void> _onShakeDetected() async {
    if (_recordings.isEmpty) {
      debugPrint("No recordings to play");
      return;
    }
    
    // Ensure index is valid
    if (_currentShakeIndex >= _recordings.length) {
      _currentShakeIndex = 0;
    }
    
    final path = _recordings[_currentShakeIndex];
    debugPrint("SHAKE! Playing Sound ${_currentShakeIndex + 1}");
    
    try {
      if (_isShakePlaying) await _shakePlayer.stop();
      await _shakePlayer.play(DeviceFileSource(path));
      
      // Increment index for next shake
      _currentShakeIndex = (_currentShakeIndex + 1) % _recordings.length;
    } catch (e) {
      debugPrint("Shake playback error: $e");
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _shakeSubscription?.cancel();
    _playerService.dispose();
    _shakePlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.notification,
    ].request();
  }

  void _notifyPlaylistUpdate() {
    FlutterBackgroundService().invoke('updatePlaylist');
    _currentShakeIndex = 0; // Reset shake index
  }

  Future<void> _loadRecordings() async {
    final recordings = await _recorderService.getRecordings();
    setState(() {
      _recordings = recordings;
    });
  }

  Future<void> _startRecording() async {
    if (_isPlaying) {
      await _playerService.stop();
    }
    
    try {
      if (await _recorderService.hasPermission()) {
        await _recorderService.startRecording();
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
          if (_recordDuration >= 5) {
            _stopRecording();
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorderService.stopRecording();
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      await _loadRecordings(); 
      _notifyPlaylistUpdate();
    }
  }
  
  Future<void> _deleteRecording(String path) async {
    if (_currentlyPlayingPath == path) {
      await _playerService.stop();
    }
    await _recorderService.deleteRecording(path);
    await _loadRecordings();
    _notifyPlaylistUpdate();
  }
  
  Future<void> _clearAll() async {
    if (_isPlaying) await _playerService.stop();
    await _recorderService.clearAll();
    await _loadRecordings();
    _currentShakeIndex = 0;
    FlutterBackgroundService().invoke('clearPlaylist');
  }
  
  Future<void> _togglePlay(String path) async {
    if (_currentlyPlayingPath == path && _isPlaying) {
      await _playerService.stop();
      setState(() {
        _currentlyPlayingPath = null;
      });
    } else {
      setState(() {
        _currentlyPlayingPath = path;
      });
      await _playerService.play(path);
    }
  }

  String _getSoundName(String path, int index) {
    return 'Sound ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Sounds',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_recordings.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Recordings List
          Expanded(
            child: _recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_none_outlined, size: 64, color: Colors.white12),
                        const SizedBox(height: 16),
                        Text(
                          'No sounds yet',
                          style: GoogleFonts.inter(
                            color: Colors.white24,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hold the button to record',
                          style: GoogleFonts.inter(
                            color: Colors.white12,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final path = _recordings[index];
                      final isPlayingThis = _currentlyPlayingPath == path && _isPlaying;
                      
                      return Dismissible(
                        key: Key(path),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline, color: Colors.white38),
                        ),
                        onDismissed: (_) => _deleteRecording(path),
                        child: GestureDetector(
                          onTap: () => _togglePlay(path),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isPlayingThis ? Colors.white : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: GoogleFonts.inter(
                                    color: isPlayingThis ? Colors.black38 : Colors.white38,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    _getSoundName(path, index),
                                    style: GoogleFonts.inter(
                                      color: isPlayingThis ? Colors.black : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isPlayingThis ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                  color: isPlayingThis ? Colors.black : Colors.white54,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Recording Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Text(
                  _isRecording 
                      ? '${_recordDuration}s' 
                      : 'Hold to record',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isRecording ? 100 : 80,
                    height: _isRecording ? 100 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording ? Colors.black : Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shake to play sounds',
                  style: GoogleFonts.inter(
                    color: Colors.white12,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
