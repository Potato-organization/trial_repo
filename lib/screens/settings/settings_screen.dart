// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/iap_service.dart';
import '../../ui/chaos_design.dart';

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
                  color: ChaosColors.text,
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
                    final started = await IAPService().buyPro();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          started
                              ? 'Purchase started. Chaos Pro unlocks after Google Play confirms it.'
                              : 'Purchase is not available yet. Check the Play Console product setup.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                _SectionHeader('CHAOS SETTINGS'),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SwitchRow(
                      icon: CupertinoIcons.speaker_2_fill,
                      title: 'Playback Boost',
                      subtitle:
                          'Use full app playback volume for sound effects.',
                      value: settings.stealthMode,
                      accentColor: accentColor,
                      onChanged: settings.setStealthMode,
                    ),
                    _Separator(),
                    _SwitchRow(
                      icon: CupertinoIcons.hand_raised_fill,
                      title: 'Slap Mode',
                      subtitle: 'Play the next sound when the phone is tapped.',
                      value: settings.isSlapModeEnabled,
                      accentColor: accentColor,
                      onChanged: settings.setSlapMode,
                    ),
                    if (settings.isSlapModeEnabled) ...[
                      _Separator(),
                      _SliderRow(
                        icon: CupertinoIcons.hand_draw,
                        title: 'Slap Sensitivity',
                        value: settings.slapSensitivity,
                        min: 0,
                        max: 1,
                        accentColor: accentColor,
                        displayValue: _slapSensitivityLabel(
                          settings.slapSensitivity,
                        ),
                        onChanged: settings.setSlapSensitivity,
                      ),
                    ],
                    _Separator(),
                    _SliderRow(
                      icon: CupertinoIcons.waveform,
                      title: 'Shake Sensitivity',
                      value: settings.shakeSensitivity,
                      min: 5,
                      max: 30,
                      accentColor: accentColor,
                      displayValue: settings.shakeSensitivity.toStringAsFixed(
                        1,
                      ),
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
                      displayValue:
                          '${settings.clapSensitivity.toStringAsFixed(0)} dB',
                      onChanged: settings.setClapSensitivity,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader('APP SETTINGS'),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SwitchRow(
                      icon: CupertinoIcons.bolt,
                      title: 'Background Triggers',
                      subtitle: settings.isPremium
                          ? 'Keeps working when app is closed.'
                          : 'Pro only',
                      value: settings.isPremium
                          ? settings.isBackgroundTriggersActive
                          : false,
                      accentColor: settings.isPremium
                          ? accentColor
                          : ChaosColors.faint,
                      onChanged: settings.isPremium
                          ? settings.setBackgroundTriggers
                          : (_) => _showPremiumPrompt(context, accentColor),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader('CUSTOMISATION'),
                const SizedBox(height: 12),
                _ThemeSelector(themeProvider: themeProvider),
                const SizedBox(height: 40),

                Center(
                  child: Text(
                    'Chaos Version 1.1.0',
                    style: GoogleFonts.inter(
                      color: ChaosColors.faint,
                      fontSize: 12,
                    ),
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

  static String _slapSensitivityLabel(double value) {
    if (value < 0.34) return 'Firm';
    if (value < 0.67) return 'Normal';
    return 'Light';
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
        color: ChaosColors.faint,
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
      child: Container(
        decoration: ChaosDecorations.panel(radius: 22),
        child: Column(children: children),
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
      color: ChaosColors.border,
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
            decoration: ChaosDecorations.panel(
              color: ChaosColors.panelHigh,
              radius: 14,
            ),
            child: Icon(icon, color: ChaosColors.muted, size: 18),
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
                    color: ChaosColors.text,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      color: ChaosColors.faint,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: accentColor,
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
                decoration: ChaosDecorations.panel(
                  color: ChaosColors.panelHigh,
                  radius: 14,
                ),
                child: Icon(icon, color: ChaosColors.muted, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: ChaosColors.text,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                displayValue,
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: ChaosDecorations.panel(
          color: isPremium
              ? Color.alphaBlend(
                  accentColor.withValues(alpha: 0.18),
                  ChaosColors.panelHigh,
                )
              : ChaosColors.panelHigh,
          borderColor: isPremium ? accentColor : ChaosColors.borderStrong,
          radius: 24,
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
                  color: accentColor,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Text(
                  isPremium ? 'CHAOS PRO' : 'UPGRADE TO PRO',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ChaosColors.text,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isPremium
                  ? 'All features unlocked.'
                  : 'Unlimited recordings, background triggers, and all sound packs.',
              style: GoogleFonts.inter(
                color: ChaosColors.muted,
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
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      'Go Pro - \$1.99',
                      style: GoogleFonts.inter(
                        color: ChaosColors.background,
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
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _ThemeSelector({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ChaosDecorations.panel(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ThemeChip(
                color: ChaosColors.blue,
                label: 'Blue',
                isSelected: themeProvider.currentTheme == AppTheme.blue,
                onTap: () => themeProvider.setTheme(AppTheme.blue),
              ),
              _ThemeChip(
                color: ChaosColors.green,
                label: 'Green',
                isSelected: themeProvider.currentTheme == AppTheme.green,
                onTap: () => themeProvider.setTheme(AppTheme.green),
              ),
              _ThemeChip(
                color: ChaosColors.coral,
                label: 'Coral',
                isSelected: themeProvider.currentTheme == AppTheme.coral,
                onTap: () => themeProvider.setTheme(AppTheme.coral),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
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
              color: isSelected
                  ? Color.alphaBlend(
                      color.withValues(alpha: 0.22),
                      ChaosColors.panelHigh,
                    )
                  : ChaosColors.panelHigh,
              border: Border.all(
                color: isSelected ? color : ChaosColors.border,
                width: 2.5,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 28 : 22,
                height: isSelected ? 28 : 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: ChaosColors.background,
                        size: 16,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? color : ChaosColors.faint,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
