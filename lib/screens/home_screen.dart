import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'dart:math';
import 'dart:ui';
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
      
      if (magnitude > 20.0) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime) > const Duration(seconds: 2)) {
          _lastShakeTime = now;
          _onShakeDetected();
        }
      }
    });
  }
  
  Future<void> _onShakeDetected() async {
    if (_recordings.isEmpty) return;
    
    if (_currentShakeIndex >= _recordings.length) {
      _currentShakeIndex = 0;
    }
    
    final path = _recordings[_currentShakeIndex];
    debugPrint("SHAKE! Playing Sound ${_currentShakeIndex + 1}");
    
    try {
      if (_isShakePlaying) await _shakePlayer.stop();
      await _shakePlayer.play(DeviceFileSource(path));
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
    await [Permission.microphone, Permission.notification].request();
  }

  void _notifyPlaylistUpdate() {
    FlutterBackgroundService().invoke('updatePlaylist');
    _currentShakeIndex = 0;
  }

  Future<void> _loadRecordings() async {
    final recordings = await _recorderService.getRecordings();
    setState(() {
      _recordings = recordings;
    });
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    if (_isPlaying) await _playerService.stop();
    
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.heavyImpact();
    if (_currentlyPlayingPath == path) await _playerService.stop();
    await _recorderService.deleteRecording(path);
    await _loadRecordings();
    _notifyPlaylistUpdate();
  }
  
  void _showDeleteDialog(String path, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Sound ${index + 1}?',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecording(path);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
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
      setState(() => _currentlyPlayingPath = null);
    } else {
      setState(() => _currentlyPlayingPath = path);
      await _playerService.play(path);
    }
  }
  
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _recordings.removeAt(oldIndex);
      _recordings.insert(newIndex, item);
    });
    _recorderService.reorderRecordings(_recordings);
    _notifyPlaylistUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sounds',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (_recordings.isNotEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Recordings List
            Expanded(
              child: _recordings.isEmpty
                  ? _buildEmptyState()
                  : _buildRecordingsList(),
            ),
            
            // Recording Area
            _buildRecordingArea(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
            child: Icon(Icons.mic_none_outlined, size: 48, color: Colors.white12),
          ),
          const SizedBox(height: 24),
          Text(
            'No sounds yet',
            style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hold the button to record',
            style: GoogleFonts.inter(color: Colors.white12, fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordingsList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _recordings.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final scale = Tween<double>(begin: 1.0, end: 1.05).animate(animation);
            return Transform.scale(
              scale: scale.value,
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final path = _recordings[index];
        final isPlayingThis = _currentlyPlayingPath == path && _isPlaying;
        
        return Padding(
          key: ValueKey(path),
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isPlayingThis 
                      ? Colors.white.withOpacity(0.95)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPlayingThis 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Drag handle
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.drag_indicator,
                          color: isPlayingThis ? Colors.black26 : Colors.white24,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Number badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPlayingThis 
                            ? Colors.black.withOpacity(0.1)
                            : Colors.white.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            color: isPlayingThis ? Colors.black54 : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sound name
                    Expanded(
                      child: Text(
                        'Sound ${index + 1}',
                        style: GoogleFonts.inter(
                          color: isPlayingThis ? Colors.black : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Play/Pause button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _togglePlay(path);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlayingThis 
                              ? Colors.black.withOpacity(0.15)
                              : Colors.white.withOpacity(0.1),
                        ),
                        child: Icon(
                          isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isPlayingThis ? Colors.black : Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showDeleteDialog(path, index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlayingThis 
                              ? Colors.black.withOpacity(0.08)
                              : Colors.white.withOpacity(0.05),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: isPlayingThis ? Colors.black38 : Colors.white30,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRecordingArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.02),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            _isRecording ? '${_recordDuration}s' : 'Hold to record',
            style: GoogleFonts.inter(
              color: _isRecording ? Colors.white : Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () => _stopRecording(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isRecording ? 100 : 72,
              height: _isRecording ? 100 : 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                  width: _isRecording ? 3 : 2,
                ),
                boxShadow: _isRecording ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ] : [],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none_rounded,
                color: _isRecording ? Colors.black : Colors.white,
                size: _isRecording ? 36 : 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Shake to play • Max 5s',
            style: GoogleFonts.inter(
              color: Colors.white12,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
