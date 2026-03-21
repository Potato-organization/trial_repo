import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/iap_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildPremiumCard(context, accentColor, settingsProvider.isPremium),
          const SizedBox(height: 32),
          _buildSectionTitle('Chaos Settings'),
          const SizedBox(height: 12),
          _buildSettingTile(
            'Stealth Mode',
            'Override system volume to play sounds.',
            Icons.visibility_off_outlined,
            Switch(
              value: settingsProvider.stealthMode,
              onChanged: settingsProvider.setStealthMode,
              activeColor: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSensitivitySlider(context, accentColor, settingsProvider),
          const SizedBox(height: 32),
          _buildSectionTitle('Customization'),
          const SizedBox(height: 12),
          _buildThemeSelector(context, themeProvider),
          const SizedBox(height: 32),
          _buildSectionTitle('App Settings'),
          const SizedBox(height: 12),
          _buildSettingTile(
            'Background Triggers',
            'Keep working even when app is closed.',
            Icons.bolt_outlined,
            Switch(
              value: settingsProvider.isBackgroundTriggersActive,
              onChanged: settingsProvider.setBackgroundTriggers,
              activeColor: accentColor,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Chaos Version 1.1.0 (Beta)',
              style: GoogleFonts.inter(color: Colors.white10, fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, Color accentColor, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
            ? [accentColor, accentColor.withOpacity(0.6)]
            : [const Color(0xFF1D1E33), const Color(0xFF0A0E21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: isPremium ? [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPremium ? 'CHAOS PRO' : 'UPGRADE TO PRO',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isPremium ? Colors.black : Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              Icon(
                isPremium ? Icons.verified_rounded : Icons.star_border_rounded,
                color: isPremium ? Colors.black : accentColor,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? 'You have unlocked all features!' : 'Unlock unlimited recording length, all sound packs, and no ads.',
            style: GoogleFonts.inter(
              color: isPremium ? Colors.black87 : Colors.white54,
              fontSize: 14,
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final iap = IAPService();
                await iap.buyPro();
                // We'll update premium status based on store response in a real app
                Provider.of<SettingsProvider>(context, listen: false).setPremium(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Go Premium - \$1.99', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white24,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, Widget trailing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSensitivitySlider(BuildContext context, Color accentColor, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vibration_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 16),
              const Text('Shake Sensitivity', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                settings.shakeSensitivity.toStringAsFixed(1),
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: settings.shakeSensitivity,
            min: 5.0,
            max: 30.0,
            onChanged: settings.setSensitivity,
            activeColor: accentColor,
            inactiveColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme Accent', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: NeonTheme.values.map((theme) {
              final isSelected = themeProvider.currentTheme == theme;
              Color color;
              switch(theme) {
                case NeonTheme.blue: color = Colors.blueAccent; break;
                case NeonTheme.green: color = Colors.greenAccent; break;
                case NeonTheme.pink: color = Colors.pinkAccent; break;
              }

              return GestureDetector(
                onTap: () => themeProvider.setTheme(theme),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
