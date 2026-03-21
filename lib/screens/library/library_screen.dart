import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/sound_category.dart';
import '../../services/audio/audio_player_service.dart';
import '../../providers/theme_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  String? _currentlyPlayingAsset;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        if (!state.playing) {
          setState(() {
            _currentlyPlayingAsset = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Sound Library',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: SoundCategory.categories.length,
        itemBuilder: (context, index) {
          final category = SoundCategory.categories[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      category.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category.title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: category.sounds.length,
                itemBuilder: (context, sIndex) {
                  final sound = category.sounds[sIndex];
                  final isPlaying = _currentlyPlayingAsset == sound.assetPath;

                  return GestureDetector(
                    onTap: () async {
                      if (isPlaying) {
                        await _audioPlayer.stop();
                        setState(() => _currentlyPlayingAsset = null);
                      } else {
                        setState(() => _currentlyPlayingAsset = sound.assetPath);
                        await _audioPlayer.playAsset(sound.assetPath);
                        // Since I don't have the assets, this will log but fail silently or gracefully handled by player
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPlaying ? accentColor : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPlaying ? accentColor : Colors.white12,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          sound.name,
                          style: GoogleFonts.inter(
                            color: isPlaying ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
