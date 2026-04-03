import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/iap_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final accentColor = themeProvider.accentColor;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Large-title navigation bar ─────────────────────────────────────
          SliverAppBar(
            backgroundColor: bg,
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
              title: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Premium card ──────────────────────────────────────────────
                _PremiumCard(
                  accentColor: accentColor,
                  isPremium: settings.isPremium,
                  onUpgrade: () async {
                    await IAPService().buyPro();
                    Provider.of<SettingsProvider>(context, listen: false)
                        .setPremium(true);
                  },
                ),
                const SizedBox(height: 32),

                // ── Chaos Settings ────────────────────────────────────────────
                _SectionHeader('CHAOS SETTINGS'),
                const SizedBox(height: 12),
                _SettingsGroup(children: [
                  _SwitchRow(
                    icon: CupertinoIcons.eye_slash,
                    title: 'Stealth Mode',
                    subtitle: 'Override system volume when playing.',
                    value: settings.stealthMode,
                    accentColor: accentColor,
                    onChanged: settings.setStealthMode,
                  ),
                  _Separator(),
                  _SliderRow(
                    icon: CupertinoIcons.waveform,
                    title: 'Shake Sensitivity',
                    value: settings.shakeSensitivity,
                    min: 5,
                    max: 30,
                    accentColor: accentColor,
                    displayValue: settings.shakeSensitivity.toStringAsFixed(1),
                    onChanged: settings.setSensitivity,
                  ),
                  _Separator(),
                  _SliderRow(
                    icon: CupertinoIcons.hand_point_right,
                    title: 'Clap Sensitivity',
                    value: settings.clapSensitivity,
                    min: 60,
                    max: 120,
                    accentColor: accentColor,
                    displayValue: '${settings.clapSensitivity.toStringAsFixed(0)} dB',
                    onChanged: settings.setClapSensitivity,
                  ),
                ]),
                const SizedBox(height: 32),

                // ── App Settings ──────────────────────────────────────────────
                _SectionHeader('APP SETTINGS'),
                const SizedBox(height: 12),
                _SettingsGroup(children: [
                  _SwitchRow(
                    icon: CupertinoIcons.bolt,
                    title: 'Background Triggers',
                    subtitle:
                        settings.isPremium ? 'Keeps working when app is closed.' : 'Pro only',
                    value: settings.isPremium
                        ? settings.isBackgroundTriggersActive
                        : false,
                    accentColor: settings.isPremium ? accentColor : Colors.white24,
                    onChanged: settings.isPremium
                        ? settings.setBackgroundTriggers
                        : (_) => _showPremiumPrompt(context, accentColor),
                  ),
                ]),
                const SizedBox(height: 32),

                // ── Customisation ─────────────────────────────────────────────
                _SectionHeader('CUSTOMISATION'),
                const SizedBox(height: 12),
                _ThemeSelector(themeProvider: themeProvider),
                const SizedBox(height: 40),

                // ── Footer ─────────────────────────────────────────────────────
                Center(
                  child: Text(
                    'Chaos Version 1.1.0 (Beta)',
                    style: GoogleFonts.inter(color: Colors.white12, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static void _showPremiumPrompt(BuildContext context, Color accentColor) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Pro Feature'),
        content: const Text(
          'Background Triggers requires Chaos Pro. Upgrade to unlock.',
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
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white24,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: Colors.white.withOpacity(0.06),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white54, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 15),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                        color: Colors.white30, fontSize: 12),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final Color accentColor;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white54, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 15),
                ),
              ),
              Text(
                displayValue,
                style: GoogleFonts.inter(
                    color: accentColor, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          CupertinoSlider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Color accentColor;
  final bool isPremium;
  final VoidCallback onUpgrade;

  const _PremiumCard({
    required this.accentColor,
    required this.isPremium,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isPremium
                ? LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      const Color(0xFF1D1E33),
                      const Color(0xFF0A0E21)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: accentColor.withOpacity(isPremium ? 0 : 0.3)),
            boxShadow: isPremium
                ? [
                    BoxShadow(
                        color: accentColor.withOpacity(0.25),
                        blurRadius: 30,
                        spreadRadius: 4)
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isPremium
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.star,
                    color: isPremium ? Colors.black : accentColor,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    isPremium ? 'CHAOS PRO' : 'UPGRADE TO PRO',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isPremium ? Colors.black : Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isPremium
                    ? 'All features unlocked. You\'re a chaos legend. 🎉'
                    : 'Unlimited recordings, background triggers, and all sound packs.',
                style: GoogleFonts.inter(
                  color: isPremium ? Colors.black.withOpacity(0.7) : Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onUpgrade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Go Pro — \$1.99',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _ThemeSelector({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accent Colour',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ThemeChip(
                    theme: NeonTheme.blue,
                    color: Colors.blueAccent,
                    label: 'Blue',
                    isSelected:
                        themeProvider.currentTheme == NeonTheme.blue,
                    onTap: () => themeProvider.setTheme(NeonTheme.blue),
                  ),
                  _ThemeChip(
                    theme: NeonTheme.green,
                    color: Colors.greenAccent,
                    label: 'Green',
                    isSelected:
                        themeProvider.currentTheme == NeonTheme.green,
                    onTap: () => themeProvider.setTheme(NeonTheme.green),
                  ),
                  _ThemeChip(
                    theme: NeonTheme.pink,
                    color: Colors.pinkAccent,
                    label: 'Pink',
                    isSelected:
                        themeProvider.currentTheme == NeonTheme.pink,
                    onTap: () => themeProvider.setTheme(NeonTheme.pink),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final NeonTheme theme;
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.theme,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(isSelected ? 0.25 : 0.1),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16)]
                  : [],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 28 : 22,
                height: isSelected ? 28 : 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.black, size: 16)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? color : Colors.white30,
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
