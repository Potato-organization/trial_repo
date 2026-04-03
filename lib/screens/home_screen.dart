import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../models/audio_effect.dart' as model;
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/audio/audio_player_service.dart';
import '../services/audio/audio_recorder_service.dart';
import '../services/shake_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:just_audio/just_audio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorderService _recorderService = AudioRecorderService();

  List<String> _recordings = [];
  Map<String, String> _recordingNames = {};
  bool _isRecording = false;
  Timer? _uiTimer;
  int _recordDuration = 0;

  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  model.AudioEffect _selectedEffect = model.AudioEffect.presets[0];

  // Shake
  StreamSubscription<void>? _shakeSubscription;
  int _currentShakeIndex = 0;
  final AudioPlayer _shakePlayer = AudioPlayer();
  bool _isShakePlaying = false;

  // Undo reorder
  List<String>? _previousOrder;

  // Track one-time setup in didChangeDependencies.
  bool _didSetup = false;
  StreamSubscription? _playerSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.12).animate(_pulseController);

    _requestPermissions();
    _loadRecordings();

    _shakePlayer.playerStateStream.listen((s) {
      _isShakePlaying = s.playing;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSetup) {
      _didSetup = true;
      _setupShakeDetection();

      final playerService =
          Provider.of<AudioPlayerService>(context, listen: false);
      _playerSubscription = playerService.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _currentlyPlayingPath = null;
            }
          });
        }
      });

      // Restore persisted effect index.
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final idx = settings.selectedEffectIndex
          .clamp(0, model.AudioEffect.presets.length - 1);
      _selectedEffect = model.AudioEffect.presets[idx];
    }
  }

  void _setupShakeDetection() {
    _shakeSubscription?.cancel();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final shakeService = ShakeService();
    shakeService.start(settings.shakeSensitivity);
    _shakeSubscription = shakeService.onShake.listen((_) => _onShakeDetected());
  }

  Future<void> _onShakeDetected() async {
    if (_recordings.isEmpty) return;
    if (_currentShakeIndex >= _recordings.length) _currentShakeIndex = 0;
    final path = _recordings[_currentShakeIndex];
    HapticFeedback.heavyImpact();
    try {
      if (_isShakePlaying) await _shakePlayer.stop();
      await _shakePlayer.setFilePath(path);
      await _shakePlayer.play();
      _currentShakeIndex = (_currentShakeIndex + 1) % _recordings.length;
    } catch (e) {
      debugPrint('Shake playback error: $e');
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _playerSubscription?.cancel();
    _shakeSubscription?.cancel();
    ShakeService().stop();
    _pulseController.dispose();
    _shakePlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted && mounted) {
      _showPermissionDeniedDialog();
    }
    await Permission.notification.request();
  }

  void _showPermissionDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Microphone Access Required'),
        content: const Text(
          'Chaos needs microphone access to record sounds. '
          'Please enable it in Settings.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _notifyPlaylistUpdate() {
    FlutterBackgroundService().invoke('updatePlaylist');
    _currentShakeIndex = 0;
  }

  Future<void> _loadRecordings() async {
    final recordings = await _recorderService.getRecordings();
    final names = await _recorderService.getRecordingNames();
    if (mounted) {
      setState(() {
        _recordings = recordings;
        _recordingNames = names;
      });
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    final player = Provider.of<AudioPlayerService>(context, listen: false);
    if (_isPlaying) await player.stop();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.isPremium &&
        _recordings.length >= AppConstants.maxFreeRecordings) {
      _showPremiumGate();
      return;
    }

    final hasPermission = await _recorderService.hasPermission();
    if (!hasPermission) {
      _showPermissionDeniedDialog();
      return;
    }

    await _recorderService.startRecording(
      onAutoStop: (path) async {
        await _loadRecordings();
        _notifyPlaylistUpdate();
        if (mounted) setState(() => _isRecording = false);
        _uiTimer?.cancel();
      },
    );

    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _recordDuration++);
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();
    _uiTimer?.cancel();
    final path = await _recorderService.stopRecording();
    setState(() => _isRecording = false);
    if (path != null) {
      await _loadRecordings();
      _notifyPlaylistUpdate();
    }
  }

  Future<void> _deleteRecording(String path) async {
    HapticFeedback.heavyImpact();
    final player = Provider.of<AudioPlayerService>(context, listen: false);
    if (_currentlyPlayingPath == path) await player.stop();
    await _recorderService.deleteRecording(path);
    await _loadRecordings();
    _notifyPlaylistUpdate();
  }

  void _showDeleteDialog(String path, String name) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteRecording(path);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    final player = Provider.of<AudioPlayerService>(context, listen: false);
    if (_isPlaying) await player.stop();
    await _recorderService.clearAll();
    await _loadRecordings();
    _currentShakeIndex = 0;
    FlutterBackgroundService().invoke('clearPlaylist');
  }

  Future<void> _togglePlay(String path) async {
    final player = Provider.of<AudioPlayerService>(context, listen: false);
    if (_currentlyPlayingPath == path && _isPlaying) {
      await player.stop();
      setState(() => _currentlyPlayingPath = null);
    } else {
      setState(() => _currentlyPlayingPath = path);
      await player.play(
        path,
        pitch: _selectedEffect.pitch,
        speed: _selectedEffect.speed,
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    _previousOrder = List<String>.from(_recordings);
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _recordings.removeAt(oldIndex);
      _recordings.insert(newIndex, item);
    });
    _recorderService.reorderRecordings(_recordings);
    _notifyPlaylistUpdate();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Reordered',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.white10,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              if (_previousOrder != null) {
                setState(() => _recordings = _previousOrder!);
                _recorderService.reorderRecordings(_recordings);
                _notifyPlaylistUpdate();
                _previousOrder = null;
              }
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _showRenameDialog(String path, String currentName) {
    final controller = TextEditingController(text: currentName);
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Rename Sound'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Sound name',
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              await _recorderService.setRecordingName(
                  path, controller.text.trim());
              await _loadRecordings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSoundOptions(String path, String name, int index) {
    final accentColor = Theme.of(context).colorScheme.primary;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showRenameDialog(path, name);
            },
            child: const Text('Rename'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(path)],
                text: 'Check out this sound from Chaos!',
              );
            },
            child: const Text('Share'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteDialog(path, name);
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPremiumGate() {
    final accentColor = Theme.of(context).colorScheme.primary;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Go Chaos Pro'),
        content: Text(
          'Free users can store up to ${AppConstants.maxFreeRecordings} sounds.\n'
          'Upgrade to Pro for unlimited recordings and more.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  String _recordingName(String path, int index) {
    return _recordingNames[path] ??
        (index < 9 ? 'Sound 0${index + 1}' : 'Sound ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Large-title iOS-style navigation bar ───────────────────────────
          SliverAppBar(
            backgroundColor: bg,
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
              title: Text(
                'Sounds',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              if (_recordings.isNotEmpty)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: _clearAll,
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 15),
                  ),
                ),
            ],
          ),

          // ── Recordings or empty state ─────────────────────────────────────
          _recordings.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(accentColor))
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverReorderableList(
                    itemCount: _recordings.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final path = _recordings[index];
                      final name = _recordingName(path, index);
                      final isPlayingThis =
                          _currentlyPlayingPath == path && _isPlaying;
                      return _buildRecordingTile(
                        key: ValueKey(path),
                        path: path,
                        name: name,
                        index: index,
                        isPlayingThis: isPlayingThis,
                        accentColor: accentColor,
                      );
                    },
                    proxyDecorator: (child, index, animation) =>
                        AnimatedBuilder(
                      animation: animation,
                      builder: (_, c) => Transform.scale(
                        scale: Tween<double>(begin: 1.0, end: 1.04)
                            .animate(CurvedAnimation(
                                parent: animation, curve: Curves.easeOut))
                            .value,
                        child: c,
                      ),
                      child: child,
                    ),
                  ),
                ),

          // bottom padding for the recording area
          const SliverToBoxAdapter(child: SizedBox(height: 200)),
        ],
      ),

      // ── Floating recording panel ─────────────────────────────────────────
      bottomNavigationBar: _buildRecordingPanel(accentColor, settings),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
              border:
                  Border.all(color: Colors.white.withOpacity(0.06), width: 1),
            ),
            child:
                const Icon(Icons.mic_none_rounded, size: 44, color: Colors.white12),
          ),
          const SizedBox(height: 24),
          Text(
            'No sounds yet',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hold the button below to record',
            style: GoogleFonts.inter(color: Colors.white18, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingTile({
    required Key key,
    required String path,
    required String name,
    required int index,
    required bool isPlayingThis,
    required Color accentColor,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isPlayingThis
                  ? accentColor.withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isPlayingThis
                    ? accentColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.08),
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
                      Icons.drag_indicator_rounded,
                      color: isPlayingThis ? accentColor.withOpacity(0.5) : Colors.white18,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sound name
                Expanded(
                  child: GestureDetector(
                    onLongPress: () => _showRenameDialog(path, name),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            color: isPlayingThis ? accentColor : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isPlayingThis)
                          Text(
                            '${_selectedEffect.name} · Playing',
                            style: GoogleFonts.inter(
                              color: accentColor.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Play button
                _CircleButton(
                  icon: isPlayingThis
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: isPlayingThis ? accentColor : Colors.white54,
                  bgColor: isPlayingThis
                      ? accentColor.withOpacity(0.15)
                      : Colors.white.withOpacity(0.08),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _togglePlay(path);
                  },
                ),
                const SizedBox(width: 8),
                // More options
                _CircleButton(
                  icon: Icons.more_horiz_rounded,
                  color: Colors.white38,
                  bgColor: Colors.white.withOpacity(0.06),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showSoundOptions(path, name, index);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingPanel(Color accentColor, SettingsProvider settings) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).viewPadding.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording status
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _isRecording
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  'Hold to record  •  Max ${AppConstants.maxRecordingSeconds}s',
                  style: GoogleFonts.inter(
                      color: Colors.white24, fontSize: 12),
                ),
                secondChild: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_recordDuration}s / ${AppConstants.maxRecordingSeconds}s',
                      style: GoogleFonts.inter(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Mic button
              GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                onTapCancel: () => _stopRecording(),
                child: ScaleTransition(
                  scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    width: _isRecording ? 80 : 64,
                    height: _isRecording ? 80 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? accentColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: _isRecording ? accentColor : Colors.white18,
                        width: _isRecording ? 2.5 : 1.5,
                      ),
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.35),
                                blurRadius: 30,
                                spreadRadius: 4,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      color: _isRecording ? accentColor : Colors.white54,
                      size: _isRecording ? 32 : 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildEffectSelector(accentColor, settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffectSelector(Color accentColor, SettingsProvider settings) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(model.AudioEffect.presets.length, (i) {
          final effect = model.AudioEffect.presets[i];
          final isSelected = _selectedEffect.name == effect.name;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedEffect = effect);
                settings.setSelectedEffectIndex(i);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? accentColor.withOpacity(0.6)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      effect.icon,
                      size: 14,
                      color: isSelected ? accentColor : Colors.white24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      effect.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? accentColor : Colors.white30,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
