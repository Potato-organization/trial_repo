import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/chaos_alarm.dart';
import '../../providers/theme_provider.dart';
import '../../services/alarm_service.dart';
import 'prank_tools_view.dart';

class ChaosLabScreen extends StatefulWidget {
  const ChaosLabScreen({super.key});

  @override
  State<ChaosLabScreen> createState() => _ChaosLabScreenState();
}

class _ChaosLabScreenState extends State<ChaosLabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ChaosAlarm> _alarms = [
    ChaosAlarm(id: '1', time: const TimeOfDay(hour: 7, minute: 0), isRandom: true),
    ChaosAlarm(id: '2', time: const TimeOfDay(hour: 8, minute: 30), assetPath: 'assets/sounds/memes/bruh.mp3'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Chaos Lab',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white24,
          tabs: const [
            Tab(text: 'Alarms'),
            Tab(text: 'Pranks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlarmsView(accentColor),
          _buildPranksView(accentColor),
        ],
      ),
    );
  }

  Widget _buildAlarmsView(Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Alarms',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.add_circle_outline, color: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._alarms.map((alarm) => _buildAlarmItem(alarm, accentColor)).toList(),
      ],
    );
  }

  Widget _buildAlarmItem(ChaosAlarm alarm, Color accentColor) {
    final now = DateTime.now();
    final timeStr = DateFormat.Hm().format(DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: alarm.isEnabled ? Colors.white : Colors.white38,
                  ),
                ),
                Text(
                  alarm.isRandom ? '🔀 Random Sound' : '🔊 ${alarm.assetPath != null ? "Selected Sound" : "Default"}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: alarm.isEnabled ? accentColor : Colors.white24,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: alarm.isEnabled,
            onChanged: (val) async {
              if (val) {
                final now = DateTime.now();
                final alarmTime = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);
                final finalTime = alarmTime.isBefore(now) ? alarmTime.add(const Duration(days: 1)) : alarmTime;
                await AlarmService.scheduleAlarm(finalTime, true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alarm scheduled for ${DateFormat.Hm().format(finalTime)}')));
              } else {
                await AlarmService.cancelAlarm();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alarm cancelled')));
              }
              setState(() {
                _alarms[_alarms.indexOf(alarm)] = alarm.copyWith(isEnabled: val);
              });
            },
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPranksView(Color accentColor) {
    return SingleChildScrollView(
      child: PrankToolsView(accentColor: accentColor),
    );
  }
}
