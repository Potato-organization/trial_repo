import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/sound_category.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/audio/audio_player_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  String? _currentlyPlayingAsset;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  StreamSubscription? _playerSubscription;
  bool _didSetup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSetup) {
      _didSetup = true;
      final playerService =
          Provider.of<AudioPlayerService>(context, listen: false);
      _playerSubscription = playerService.playerStateStream.listen((state) {
        if (mounted && !state.playing) {
          setState(() => _currentlyPlayingAsset = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _playOrStop(
    AudioPlayerService player,
    SettingsProvider settings,
    String assetPath,
    Color accentColor,
  ) async {
    HapticFeedback.lightImpact();
    if (_currentlyPlayingAsset == assetPath) {
      await player.stop();
      setState(() => _currentlyPlayingAsset = null);
    } else {
      setState(() => _currentlyPlayingAsset = assetPath);
      await player.playAsset(assetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final player = Provider.of<AudioPlayerService>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);

    // Build favourite sounds list from all categories.
    final allSounds = SoundCategory.categories
        .expand((c) => c.sounds)
        .toList();
    final favourites =
        allSounds.where((s) => settings.favoriteAssets.contains(s.assetPath)).toList();

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
                'Sound Library',
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
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: [
                const Tab(text: 'All Sounds'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Favourites'),
                      if (settings.favoriteAssets.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${settings.favoriteAssets.length}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllSounds(player, settings, accentColor),
            _buildFavourites(player, settings, favourites, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSounds(
    AudioPlayerService player,
    SettingsProvider settings,
    Color accentColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: SoundCategory.categories.length,
      itemBuilder: (context, index) {
        final category = SoundCategory.categories[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Row(
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    category.title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ...category.sounds.map((sound) => _buildSoundTile(
                  sound, player, settings, accentColor)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFavourites(
    AudioPlayerService player,
    SettingsProvider settings,
    List<PreloadedSound> favourites,
    Color accentColor,
  ) {
    if (favourites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
              child:
                  const Icon(CupertinoIcons.heart, size: 40, color: Colors.white12),
            ),
            const SizedBox(height: 20),
            Text(
              'No favourites yet',
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap ♡ on any sound to save it here',
              style:
                  GoogleFonts.inter(color: Colors.white24, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: favourites.length,
      itemBuilder: (context, i) => _buildSoundTile(
          favourites[i], player, settings, accentColor),
    );
  }

  Widget _buildSoundTile(
    PreloadedSound sound,
    AudioPlayerService player,
    SettingsProvider settings,
    Color accentColor,
  ) {
    final isPlaying = _currentlyPlayingAsset == sound.assetPath;
    final isFav = settings.favoriteAssets.contains(sound.assetPath);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isPlaying
                  ? accentColor.withOpacity(0.12)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPlaying
                    ? accentColor.withOpacity(0.4)
                    : Colors.white.withOpacity(0.07),
              ),
            ),
            child: Row(
              children: [
                // Favourite button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settings.toggleFavorite(sound.assetPath);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      key: ValueKey(isFav),
                      color: isFav ? Colors.pinkAccent : Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Sound name
                Expanded(
                  child: Text(
                    sound.name,
                    style: GoogleFonts.inter(
                      color: isPlaying ? accentColor : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Play/Stop
                GestureDetector(
                  onTap: () => _playOrStop(
                      player, settings, sound.assetPath, accentColor),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPlaying
                          ? accentColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: isPlaying ? accentColor : Colors.white54,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
