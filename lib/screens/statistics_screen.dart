import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../services/statistics_service.dart';
import '../providers/settings_provider.dart';
import '../constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<MapEntry<String, int>> _stats = [];
  bool _loading = true;
  int _totalPlays = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final entries = await StatisticsService.getTopSounds();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    if (mounted) {
      setState(() {
        _stats = entries;
        _totalPlays = total;
        _loading = false;
      });
    }
  }

  Future<void> _clearStats() async {
    await StatisticsService.clearStats();
    await _loadStats();
  }

  String _displayName(String id) {
    // Asset paths show the file name; file system paths show basename.
    final base = p.basenameWithoutExtension(id);
    return base.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Large-title iOS-style app bar ──────────────────────────────────
          SliverAppBar(
            backgroundColor: bg,
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
              title: Text(
                'Statistics',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              if (_stats.isNotEmpty)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () => _showClearConfirm(context),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 15),
                  ),
                ),
            ],
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_stats.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else ...[
            // ── Summary card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _SummaryCard(
                  totalPlays: _totalPlays,
                  uniqueSounds: _stats.length,
                  accentColor: accentColor,
                ),
              ),
            ),

            // ── Section header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  'TOP SOUNDS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white24,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            // ── Stats list ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = _stats[index];
                    final fraction =
                        _totalPlays > 0 ? entry.value / _totalPlays : 0.0;
                    final isFirst = index == 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StatRow(
                        rank: index + 1,
                        name: _displayName(entry.key),
                        count: entry.value,
                        fraction: fraction,
                        accentColor: accentColor,
                        highlight: isFirst,
                      ),
                    );
                  },
                  childCount: _stats.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                size: 40, color: Colors.white12),
          ),
          const SizedBox(height: 20),
          Text(
            'No plays yet',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start playing sounds to see stats here',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Clear Statistics?'),
        content: const Text('All play history will be erased.'),
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
              _clearStats();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int totalPlays;
  final int uniqueSounds;
  final Color accentColor;

  const _SummaryCard({
    required this.totalPlays,
    required this.uniqueSounds,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              _Stat(label: 'Total Plays', value: '$totalPlays', accentColor: accentColor),
              const SizedBox(width: 1),
              _divider(),
              _Stat(label: 'Unique Sounds', value: '$uniqueSounds', accentColor: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white12,
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  const _Stat({required this.label, required this.value, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final int rank;
  final String name;
  final int count;
  final double fraction;
  final Color accentColor;
  final bool highlight;

  const _StatRow({
    required this.rank,
    required this.name,
    required this.count,
    required this.fraction,
    required this.accentColor,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: highlight
                ? accentColor.withOpacity(0.08)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? accentColor.withOpacity(0.25)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: highlight
                          ? accentColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: highlight ? accentColor : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? "play" : "plays"}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: highlight ? accentColor : Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    highlight ? accentColor : accentColor.withOpacity(0.5),
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
