import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'library/library_screen.dart';
import 'chaos_lab/chaos_lab_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics_screen.dart';
import '../ui/chaos_design.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    LibraryScreen(),
    ChaosLabScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ChaosColors.panel,
          border: Border(top: BorderSide(color: ChaosColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: ChaosColors.panel,
            elevation: 0,
            selectedItemColor: accentColor,
            unselectedItemColor: ChaosColors.faint,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.waveform, size: 22),
                activeIcon: Icon(CupertinoIcons.waveform, size: 22),
                label: 'Sounds',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.music_note_list, size: 22),
                activeIcon: Icon(CupertinoIcons.music_note_list, size: 22),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.lab_flask, size: 22),
                activeIcon: Icon(Icons.science_rounded, size: 22),
                label: 'Lab',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chart_bar, size: 22),
                activeIcon: Icon(Icons.bar_chart_rounded, size: 22),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings, size: 22),
                activeIcon: Icon(Icons.settings_rounded, size: 22),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
