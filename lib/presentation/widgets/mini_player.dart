import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:provider/provider.dart';

/// Mini-player fijo en la parte inferior con hero animation hacia el
/// reproductor completo.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const String heroTag = 'harmonix-mini-player';

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Hero(
      tag: heroTag,
      flightShuttleBuilder: _flightShuttleBuilder,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          decoration: BoxDecoration(
            color: HarmonixColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: player.openFullPlayer,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _Cover(song: song, size: 48),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HarmonixColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HarmonixColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _PlayPauseButton(player: player),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded,
                            color: HarmonixColors.textPrimary),
                        onPressed: player.next,
                      ),
                    ],
                  ),
                ),
              ),
              // Barra de progreso delgada
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: LinearProgressIndicator(
                  value: player.duration.inMilliseconds == 0
                      ? 0
                      : (player.position.inMilliseconds /
                              player.duration.inMilliseconds)
                          .clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor:
                      HarmonixColors.accent.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation(HarmonixColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Transición hero suave: escala + fade.
  Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: toHeroContext.widget,
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) {
        return ScaleTransition(scale: anim, child: child);
      },
      child: player.isPlaying
          ? IconButton(
              key: const ValueKey('pause'),
              icon: const Icon(Icons.pause_rounded,
                  color: HarmonixColors.accentBright),
              onPressed: player.togglePlay,
            )
          : IconButton(
              key: const ValueKey('play'),
              icon: const Icon(Icons.play_arrow_rounded,
                  color: HarmonixColors.accentBright),
              onPressed: player.togglePlay,
            ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.song, required this.size});
  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (song.thumbnailUrl == null || song.thumbnailUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: HarmonixColors.surfaceVariant,
        child: Icon(Icons.music_note_rounded,
            color: HarmonixColors.accent, size: size * 0.5),
      );
    }
    return CachedNetworkImage(
      imageUrl: song.thumbnailUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: HarmonixColors.surfaceVariant,
        child: Icon(Icons.music_note_rounded,
            color: HarmonixColors.accent, size: size * 0.5),
      ),
      errorWidget: (_, __, ___) => Container(
        color: HarmonixColors.surfaceVariant,
        child: Icon(Icons.broken_image_outlined,
            color: HarmonixColors.textSecondary, size: size * 0.4),
      ),
    );
  }
}
