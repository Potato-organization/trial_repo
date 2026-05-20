import 'dart:async';
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
import '../services/audio/audio_player_service.dart';
import '../services/audio/audio_recorder_service.dart';
import '../services/shake_service.dart';
import '../services/slap_impact_detector.dart';
import '../services/slap_service.dart';
import '../ui/chaos_design.dart';
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
  StreamSubscription<SlapImpact>? _slapSubscription;
  int _currentShakeIndex = 0;
  final AudioPlayer _shakePlayer = AudioPlayer();
  bool _isShakePlaying = false;
  SettingsProvider? _settingsProvider;

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
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(_pulseController);

    _requestPermissions();
    _loadRecordings();

    _shakePlayer.playerStateStream.listen((s) {
      _isShakePlaying = s.playing;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_settingsProvider != settings) {
      _settingsProvider?.removeListener(_handleSettingsChanged);
      _settingsProvider = settings;
      settings.addListener(_handleSettingsChanged);
    }

    if (!_didSetup) {
      _didSetup = true;
      _setupMotionDetection(settings);

      final playerService = Provider.of<AudioPlayerService>(
        context,
        listen: false,
      );
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
      final idx = settings.selectedEffectIndex.clamp(
        0,
        model.AudioEffect.presets.length - 1,
      );
      _selectedEffect = model.AudioEffect.presets[idx];
    }
  }

  void _handleSettingsChanged() {
    if (!mounted || _settingsProvider == null) return;
    _setupMotionDetection(_settingsProvider!);
  }

  void _setupMotionDetection(SettingsProvider settings) {
    final shakeService = ShakeService();
    _shakeSubscription ??= shakeService.onShake.listen(
      (_) => _onShakeDetected(),
    );
    shakeService.start(settings.shakeSensitivity);
    shakeService.updateSensitivity(settings.shakeSensitivity);
    _syncSlapDetection(settings);
  }

  void _syncSlapDetection(SettingsProvider settings) {
    final slapService = SlapService();
    if (settings.isSlapModeEnabled) {
      slapService.start(sensitivity: settings.slapSensitivity);
      slapService.updateSensitivity(settings.slapSensitivity);
      _slapSubscription ??= slapService.onSlap.listen(_onSlapDetected);
    } else {
      _slapSubscription?.cancel();
      _slapSubscription = null;
      slapService.stop();
    }
  }

  Future<void> _onShakeDetected() async {
    HapticFeedback.heavyImpact();
    await _playMotionTriggeredSound(volume: 1.0);
  }

  Future<void> _playMotionTriggeredSound({required double volume}) async {
    if (_recordings.isEmpty) return;
    if (_currentShakeIndex >= _recordings.length) _currentShakeIndex = 0;
    final path = _recordings[_currentShakeIndex];
    final playbackVolume = volume.clamp(0.0, 1.0).toDouble();
    try {
      if (_isShakePlaying) await _shakePlayer.stop();
      await _shakePlayer.setVolume(playbackVolume);
      await _shakePlayer.setFilePath(path);
      await _shakePlayer.play();
      _currentShakeIndex = (_currentShakeIndex + 1) % _recordings.length;
    } catch (e) {
      debugPrint('Shake playback error: $e');
    }
  }

  Future<void> _onSlapDetected(SlapImpact impact) async {
    HapticFeedback.selectionClick();
    await _playMotionTriggeredSound(volume: _volumeForSlapForce(impact.force));
  }

  double _volumeForSlapForce(double force) {
    final normalizedForce = force.clamp(0.0, 1.0).toDouble();
    return 0.35 + (normalizedForce * 0.65);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _playerSubscription?.cancel();
    _settingsProvider?.removeListener(_handleSettingsChanged);
    _shakeSubscription?.cancel();
    _slapSubscription?.cancel();
    ShakeService().stop();
    SlapService().stop();
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
    if (!mounted) return;

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
            style: GoogleFonts.inter(color: ChaosColors.text),
          ),
          backgroundColor: ChaosColors.panelHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                path,
                controller.text.trim(),
              );
              await _loadRecordings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSoundOptions(String path, String name, int index) {
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
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(path)],
                  text: 'Check out this sound from Chaos!',
                ),
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
                  color: ChaosColors.text,
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
                      color: ChaosColors.faint,
                      fontSize: 15,
                    ),
                  ),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: _buildTriggerStatusStrip(settings, accentColor),
          ),

          // ── Recordings or empty state ─────────────────────────────────────
          _recordings.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(accentColor))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: SliverReorderableList(
                    itemCount: _recordings.length,
                    // ignore: deprecated_member_use
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
                                .animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                )
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

  Widget _buildTriggerStatusStrip(
    SettingsProvider settings,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ChaosDecorations.panel(
          color: ChaosColors.panel,
          radius: 22,
        ),
        child: Row(
          children: [
            _StatusPill(
              icon: CupertinoIcons.waveform,
              label: '${_recordings.length} sounds',
              color: accentColor,
            ),
            const SizedBox(width: 8),
            _StatusPill(
              icon: CupertinoIcons.hand_raised_fill,
              label: settings.isSlapModeEnabled ? 'Slap armed' : 'Slap off',
              color: settings.isSlapModeEnabled
                  ? ChaosColors.coral
                  : ChaosColors.faint,
            ),
            const SizedBox(width: 8),
            _StatusPill(
              icon: CupertinoIcons.device_phone_portrait,
              label: 'Shake ready',
              color: ChaosColors.green,
            ),
          ],
        ),
      ),
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
              color: ChaosColors.panelHigh,
              border: Border.all(color: ChaosColors.border),
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              size: 44,
              color: ChaosColors.faint,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No sounds yet',
            style: GoogleFonts.inter(
              color: ChaosColors.muted,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hold the button below to record',
            style: GoogleFonts.inter(color: ChaosColors.faint, fontSize: 14),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: isPlayingThis
            ? ChaosDecorations.selectedPanel(accentColor, radius: 20)
            : ChaosDecorations.panel(color: ChaosColors.panel, radius: 20),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: isPlayingThis
                      ? accentColor.withValues(alpha: 0.65)
                      : ChaosColors.faint,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onLongPress: () => _showRenameDialog(path, name),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        color: isPlayingThis ? accentColor : ChaosColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isPlayingThis)
                      Text(
                        '${_selectedEffect.name} · Playing',
                        style: GoogleFonts.inter(
                          color: accentColor.withValues(alpha: 0.75),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _CircleButton(
              icon: isPlayingThis
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: isPlayingThis ? accentColor : ChaosColors.muted,
              bgColor: isPlayingThis
                  ? accentColor.withValues(alpha: 0.16)
                  : ChaosColors.panelPressed,
              onTap: () {
                HapticFeedback.lightImpact();
                _togglePlay(path);
              },
            ),
            const SizedBox(width: 8),
            _CircleButton(
              icon: Icons.more_horiz_rounded,
              color: ChaosColors.muted,
              bgColor: ChaosColors.panelPressed,
              onTap: () {
                HapticFeedback.selectionClick();
                _showSoundOptions(path, name, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingPanel(Color accentColor, SettingsProvider settings) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: ChaosColors.panel,
        border: Border(top: BorderSide(color: ChaosColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isRecording
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              'Hold to record  -  Max ${AppConstants.maxRecordingSeconds}s',
              style: GoogleFonts.inter(color: ChaosColors.faint, fontSize: 12),
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
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () => _stopRecording(),
            child: ScaleTransition(
              scale: _isRecording
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                width: _isRecording ? 80 : 64,
                height: _isRecording ? 80 : 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? accentColor.withValues(alpha: 0.16)
                      : ChaosColors.panelPressed,
                  border: Border.all(
                    color: _isRecording
                        ? accentColor
                        : ChaosColors.borderStrong,
                    width: _isRecording ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _isRecording ? accentColor : ChaosColors.muted,
                  size: _isRecording ? 32 : 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildEffectSelector(accentColor, settings),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: isSelected
                    ? ChaosDecorations.selectedPanel(accentColor, radius: 999)
                    : ChaosDecorations.panel(
                        color: ChaosColors.panelHigh,
                        radius: 999,
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      effect.icon,
                      size: 14,
                      color: isSelected ? accentColor : ChaosColors.faint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      effect.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? accentColor : ChaosColors.muted,
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

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.12),
            ChaosColors.panelHigh,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: ChaosColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
