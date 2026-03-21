import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/trigger_service.dart';
import '../../services/audio/audio_player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

class PrankToolsView extends StatefulWidget {
  final Color accentColor;
  const PrankToolsView({super.key, required this.accentColor});

  @override
  State<PrankToolsView> createState() => _PrankToolsViewState();
}

class _PrankToolsViewState extends State<PrankToolsView> {
  int _timerSeconds = 0;
  bool _isTimerActive = false;
  bool _clapDetectionActive = false;
  bool _lightTriggerActive = false;
  Timer? _timer;
  final AudioPlayerService _player = AudioPlayerService();

  void _startTimer() {
    setState(() => _isTimerActive = true);
    _timer = Timer(Duration(seconds: _timerSeconds), () async {
      if (mounted) {
        setState(() {
          _isTimerActive = false;
          _timerSeconds = 0;
        });

        // Actually trigger chaos
        final prefs = await SharedPreferences.getInstance();
        final playlist = prefs.getStringList('playlist') ?? [];
        if (playlist.isNotEmpty) {
          final random = Random();
          final path = playlist[random.nextInt(playlist.length)];
          await _player.play(path);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BOOM! Chaos unleashed!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prank Tools',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildToolCard(
            'Prank Timer',
            'Delayed sound playback. Set it and hide!',
            Icons.timer_outlined,
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [10, 30, 60, 300].map((s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${s}s'),
                      selected: _timerSeconds == s,
                      onSelected: (val) => setState(() => _timerSeconds = s),
                      selectedColor: widget.accentColor.withOpacity(0.2),
                      labelStyle: TextStyle(color: _timerSeconds == s ? widget.accentColor : Colors.white24),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _timerSeconds > 0 && !_isTimerActive ? _startTimer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTimerActive ? Colors.redAccent : widget.accentColor,
                  ),
                  child: Text(
                    _isTimerActive ? 'Active...' : 'Start Timer',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            'Clap Detection',
            'Trigger a sound when someone claps.',
            Icons.speaker_group_outlined,
            SwitchListTile(
              value: _clapDetectionActive,
              onChanged: (val) {
                setState(() => _clapDetectionActive = val);
                TriggerService.toggleClapDetection(val);
              },
              title: const Text('Enable Clap Trigger', style: TextStyle(color: Colors.white70)),
              activeColor: widget.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            'Light Trigger',
            'Plays sound when phone moves from dark to light.',
            Icons.light_mode_outlined,
            SwitchListTile(
              value: _lightTriggerActive,
              onChanged: (val) {
                setState(() => _lightTriggerActive = val);
                TriggerService.toggleLightTrigger(val);
              },
              title: const Text('Enable Light Trigger', style: TextStyle(color: Colors.white70)),
              activeColor: widget.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, String subtitle, IconData icon, Widget control) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          control,
        ],
      ),
    );
  }
}
