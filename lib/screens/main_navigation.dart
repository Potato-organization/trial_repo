import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'library/library_screen.dart';
import 'chaos_lab/chaos_lab_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics_screen.dart';

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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              border: Border(
                top: BorderSide(color: accentColor.withOpacity(0.1), width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: accentColor,
              unselectedItemColor: Colors.white24,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11),
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
      ),
    );
  }
}

