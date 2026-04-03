import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../models/chaos_alarm.dart';
import '../../providers/settings_provider.dart';
import '../../services/alarm_service.dart';
import '../../services/audio/audio_player_service.dart';
import 'prank_tools_view.dart';

class ChaosLabScreen extends StatefulWidget {
  const ChaosLabScreen({super.key});

  @override
  State<ChaosLabScreen> createState() => _ChaosLabScreenState();
}

class _ChaosLabScreenState extends State<ChaosLabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Alarms ─────────────────────────────────────────────────────────────────
  List<ChaosAlarm> _alarms = [];

  // ── Chaos Mode ─────────────────────────────────────────────────────────────
  bool _chaosModeActive = false;
  Timer? _chaosModeTimer;
  int _chaosMinInterval = 10; // seconds
  int _chaosMaxInterval = 60; // seconds
  String _chaosModeStatus = 'Idle';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAlarms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chaosModeTimer?.cancel();
    super.dispose();
  }

  // ── Alarm persistence ───────────────────────────────────────────────────────

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.alarmsKey) ?? [];
    if (mounted) {
      setState(() {
        _alarms = raw.map((s) {
          try {
            return ChaosAlarm.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        }).whereType<ChaosAlarm>().toList();
      });
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(AppConstants.alarmsKey, raw);
  }

  Future<void> _addAlarm() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final alarmId = await AlarmService.nextAlarmId();
    final alarm = ChaosAlarm(
      id: 'alarm_$alarmId',
      androidAlarmId: alarmId,
      time: picked,
      isRandom: true,
    );

    setState(() => _alarms.add(alarm));
    await _saveAlarms();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm added for ${picked.format(context)}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteAlarm(ChaosAlarm alarm) async {
    await AlarmService.cancelAlarm(alarm.androidAlarmId);
    setState(() => _alarms.removeWhere((a) => a.id == alarm.id));
    await _saveAlarms();
  }

  Future<void> _toggleAlarm(ChaosAlarm alarm, bool val) async {
    if (val) {
      final now = DateTime.now();
      final alarmTime = DateTime(
        now.year, now.month, now.day, alarm.time.hour, alarm.time.minute,
      );
      final finalTime =
          alarmTime.isBefore(now) ? alarmTime.add(const Duration(days: 1)) : alarmTime;
      await AlarmService.scheduleAlarm(alarm.androidAlarmId, finalTime, true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Alarm set for ${DateFormat.Hm().format(finalTime)}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      await AlarmService.cancelAlarm(alarm.androidAlarmId);
    }

    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx != -1) {
      setState(() => _alarms[idx] = alarm.copyWith(isEnabled: val));
      await _saveAlarms();
    }
  }

  // ── Chaos Mode ──────────────────────────────────────────────────────────────

  void _toggleChaosMode(bool val, AudioPlayerService player) {
    HapticFeedback.heavyImpact();
    setState(() {
      _chaosModeActive = val;
      _chaosModeStatus = val ? 'Running…' : 'Idle';
    });
    if (val) {
      _scheduleChaosSound(player);
    } else {
      _chaosModeTimer?.cancel();
    }
  }

  void _scheduleChaosSound(AudioPlayerService player) async {
    final range = _chaosMaxInterval - _chaosMinInterval;
    final delay =
        _chaosMinInterval + (range > 0 ? Random().nextInt(range) : 0);
    setState(() => _chaosModeStatus = 'Next in ${delay}s…');
    _chaosModeTimer = Timer(Duration(seconds: delay), () async {
      if (!_chaosModeActive) return;
      final prefs = await SharedPreferences.getInstance();
      final playlist = prefs.getStringList(AppConstants.playlistKey) ?? [];
      if (playlist.isNotEmpty) {
        final path = playlist[Random().nextInt(playlist.length)];
        HapticFeedback.heavyImpact();
        await player.play(path);
      }
      if (_chaosModeActive && mounted) {
        _scheduleChaosSound(player);
      }
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: bg,
            expandedHeight: 120,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 16, 56),
              title: Text(
                'Chaos Lab',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: accentColor,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: accentColor,
              unselectedLabelColor: Colors.white24,
              labelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Alarms'),
                Tab(text: 'Pranks'),
                Tab(text: 'Chaos Mode'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAlarmsView(accentColor),
            PrankToolsView(accentColor: accentColor),
            _buildChaosModeView(accentColor),
          ],
        ),
      ),
    );
  }

  // ── Alarms tab ──────────────────────────────────────────────────────────────

  Widget _buildAlarmsView(Color accentColor) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Alarms',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white24,
                    letterSpacing: 1.2,
                  ),
                ),
                GestureDetector(
                  onTap: _addAlarm,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded, color: accentColor, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (_alarms.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.alarm, size: 44, color: Colors.white12),
                  const SizedBox(height: 16),
                  Text(
                    'No alarms set',
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 17,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to schedule a chaos alarm',
                    style:
                        GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) =>
                    _buildAlarmTile(_alarms[i], accentColor),
                childCount: _alarms.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildAlarmTile(ChaosAlarm alarm, Color accentColor) {
    final now = DateTime.now();
    final timeStr = DateFormat.Hm().format(
        DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute));

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child:
            const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 22),
      ),
      onDismissed: (_) => _deleteAlarm(alarm),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                color: alarm.isEnabled
                    ? accentColor.withOpacity(0.08)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: alarm.isEnabled
                      ? accentColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: alarm.isEnabled ? Colors.white : Colors.white30,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alarm.isRandom ? '🔀 Random Sound' : '🔊 Custom Sound',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: alarm.isEnabled
                                ? accentColor.withOpacity(0.8)
                                : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: alarm.isEnabled,
                    activeColor: accentColor,
                    onChanged: (val) => _toggleAlarm(alarm, val),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Chaos Mode tab ──────────────────────────────────────────────────────────

  Widget _buildChaosModeView(Color accentColor) {
    final player = Provider.of<AudioPlayerService>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: _chaosModeActive
                      ? LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.2),
                            accentColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _chaosModeActive
                      ? null
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _chaosModeActive
                        ? accentColor.withOpacity(0.4)
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _chaosModeActive
                                ? accentColor.withOpacity(0.2)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shuffle_rounded,
                            color:
                                _chaosModeActive ? accentColor : Colors.white38,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chaos Mode',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _chaosModeStatus,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _chaosModeActive
                                      ? accentColor
                                      : Colors.white24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: _chaosModeActive,
                          activeColor: accentColor,
                          onChanged: (val) =>
                              _toggleChaosMode(val, player),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Plays random sounds at random intervals. Perfect for leaving the phone behind!',
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Interval settings
          Text(
            'INTERVAL',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white24,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          _buildIntervalCard(accentColor),
        ],
      ),
    );
  }

  Widget _buildIntervalCard(Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            children: [
              _IntervalRow(
                label: 'Min',
                value: _chaosMinInterval,
                min: 5,
                max: 120,
                accentColor: accentColor,
                enabled: !_chaosModeActive,
                onChanged: (v) => setState(() => _chaosMinInterval = v),
              ),
              const SizedBox(height: 16),
              _IntervalRow(
                label: 'Max',
                value: _chaosMaxInterval,
                min: 5,
                max: 300,
                accentColor: accentColor,
                enabled: !_chaosModeActive,
                onChanged: (v) => setState(() {
                  _chaosMaxInterval = v;
                  if (_chaosMaxInterval < _chaosMinInterval) {
                    _chaosMinInterval = _chaosMaxInterval;
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final Color accentColor;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _IntervalRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: CupertinoSlider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min),
            activeColor: enabled ? accentColor : Colors.white24,
            onChanged: enabled ? (v) => onChanged(v.round()) : null,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${value}s',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
                color: enabled ? accentColor : Colors.white24,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ),
      ],
    );
  }
}
