// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/trigger_service.dart';
import '../../ui/chaos_design.dart';

class PrankToolsView extends StatefulWidget {
  final Color accentColor;
  const PrankToolsView({super.key, required this.accentColor});

  @override
  State<PrankToolsView> createState() => _PrankToolsViewState();
}

class _PrankToolsViewState extends State<PrankToolsView> {
  int _timerSeconds = 0;
  bool _isTimerActive = false;
  Timer? _countdownTimer;
  int _countdown = 0;

  bool _clapDetectionActive = false;
  bool _lightTriggerActive = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    // Always cancel trigger subscriptions on widget dispose.
    if (_clapDetectionActive) TriggerService.toggleClapDetection(false);
    if (_lightTriggerActive) TriggerService.toggleLightTrigger(false);
    super.dispose();
  }

  // ── Timer prank ────────────────────────────────────────────────────────────

  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTimerActive = true;
      _countdown = _timerSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_countdown <= 1) {
        t.cancel();
        await _fireChaos();
        if (mounted) {
          setState(() {
            _isTimerActive = false;
            _countdown = 0;
          });
        }
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  void _cancelTimer() {
    HapticFeedback.lightImpact();
    _countdownTimer?.cancel();
    setState(() {
      _isTimerActive = false;
      _countdown = 0;
    });
  }

  Future<void> _fireChaos() async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    final playlist = prefs.getStringList(AppConstants.playlistKey) ?? [];
    if (playlist.isNotEmpty) {
      final path = playlist[Random().nextInt(playlist.length)];
      if (!mounted) return;
      final player = Provider.of<AudioPlayerService>(context, listen: false);
      await player.play(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chaos unleashed.',
            style: GoogleFonts.inter(color: ChaosColors.text),
          ),
          backgroundColor: ChaosColors.panelHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ── Clap detection ─────────────────────────────────────────────────────────

  Future<void> _toggleClap(bool val) async {
    if (val) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final granted = await TriggerService.toggleClapDetection(
        true,
        sensitivity: settings.clapSensitivity,
      );
      if (!granted) {
        _showPermissionDenied('Microphone');
        return;
      }
    } else {
      await TriggerService.toggleClapDetection(false);
    }
    if (!mounted) return;
    setState(() => _clapDetectionActive = val);
  }

  Future<void> _setClapSensitivity(
    SettingsProvider settings,
    double value,
  ) async {
    settings.setClapSensitivity(value);
    if (_clapDetectionActive) {
      await TriggerService.toggleClapDetection(false);
      await TriggerService.toggleClapDetection(true, sensitivity: value);
    }
  }

  // ── Light trigger ──────────────────────────────────────────────────────────

  Future<void> _toggleLight(bool val) async {
    await TriggerService.toggleLightTrigger(val);
    setState(() => _lightTriggerActive = val);
  }

  void _showPermissionDenied(String type) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('$type Access Required'),
        content: Text(
          'Please grant $type permission in Settings to use this trigger.',
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

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Text(
          'PRANK TOOLS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ChaosColors.faint,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildTimerCard(),
        const SizedBox(height: 14),
        _buildClapCard(),
        const SizedBox(height: 14),
        _buildLightCard(),
      ],
    );
  }

  Widget _buildTimerCard() {
    return _PrankCard(
      icon: CupertinoIcons.timer,
      title: 'Prank Timer',
      subtitle: 'Set it, hide it, and wait for chaos.',
      accentColor: widget.accentColor,
      child: Column(
        children: [
          // Chip row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [10, 30, 60, 120, 300].map((s) {
                final selected = _timerSeconds == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _isTimerActive
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _timerSeconds = s);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Color.alphaBlend(
                                widget.accentColor.withValues(alpha: 0.16),
                                ChaosColors.panelHigh,
                              )
                            : ChaosColors.panelHigh,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? widget.accentColor.withValues(alpha: 0.6)
                              : ChaosColors.border,
                        ),
                      ),
                      child: Text(
                        s >= 60 ? '${s ~/ 60}m' : '${s}s',
                        style: TextStyle(
                          color: selected
                              ? widget.accentColor
                              : ChaosColors.muted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          // Start / cancel row
          if (_isTimerActive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Detonating in ${_countdown}s',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                onPressed: _cancelTimer,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: AnimatedOpacity(
                opacity: _timerSeconds > 0 ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _timerSeconds > 0 ? _startTimer : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        widget.accentColor.withValues(alpha: 0.14),
                        ChaosColors.panelHigh,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _timerSeconds > 0 ? 'Start Timer' : 'Select a duration',
                        style: GoogleFonts.inter(
                          color: widget.accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClapCard() {
    return _PrankCard(
      icon: CupertinoIcons.hand_raised,
      title: 'Clap Detection',
      subtitle: 'Triggers a sound when someone claps.',
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enable',
                style: GoogleFonts.inter(
                  color: ChaosColors.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              CupertinoSwitch(
                value: _clapDetectionActive,
                activeColor: widget.accentColor,
                onChanged: _toggleClap,
              ),
            ],
          ),
          if (_clapDetectionActive) ...[
            const SizedBox(height: 12),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Clap Sensitivity',
                        style: GoogleFonts.inter(
                          color: ChaosColors.faint,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${settings.clapSensitivity.toStringAsFixed(0)} dB',
                        style: GoogleFonts.inter(
                          color: widget.accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  CupertinoSlider(
                    value: settings.clapSensitivity,
                    min: 60,
                    max: 120,
                    divisions: 60,
                    activeColor: widget.accentColor,
                    onChanged: (value) => _setClapSensitivity(settings, value),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLightCard() {
    return _PrankCard(
      icon: CupertinoIcons.sun_max,
      title: 'Light Trigger',
      subtitle: 'Plays a sound when the room lights up.',
      accentColor: widget.accentColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Enable',
            style: GoogleFonts.inter(
              color: ChaosColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          CupertinoSwitch(
            value: _lightTriggerActive,
            activeColor: widget.accentColor,
            onChanged: _toggleLight,
          ),
        ],
      ),
    );
  }
}

class _PrankCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget child;

  const _PrankCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ChaosDecorations.panel(color: ChaosColors.panel, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: ChaosDecorations.panel(
                  color: Color.alphaBlend(
                    accentColor.withValues(alpha: 0.12),
                    ChaosColors.panelHigh,
                  ),
                  borderColor: accentColor.withValues(alpha: 0.35),
                  radius: 16,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ChaosColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: ChaosColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
