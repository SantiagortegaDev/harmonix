import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/data/services/download_service.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/widgets/favorite_button.dart';
import 'package:harmonix/presentation/widgets/wavy_slider.dart';
import 'package:provider/provider.dart';

/// Reproductor a pantalla completa con wavy slider, portada, letras
/// sincronizadas, controles avanzados y panel de descarga.
class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    return Scaffold(
      backgroundColor: HarmonixColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo con blur de la portada
            if (song?.thumbnailUrl != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.18,
                  child: CachedNetworkImage(
                    imageUrl: song!.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: HarmonixColors.background),
                    errorWidget: (_, __, ___) =>
                        Container(color: HarmonixColors.background),
                  ),
                ),
              ),
            Container(color: HarmonixColors.background.withValues(alpha: 0.4)),
            // Contenido principal
            Column(
              children: [
                _TopBar(player: player),
                Expanded(
                  child: _NowPlayingBody(player: player, song: song),
                ),
                _ProgressBar(player: player),
                _Controls(player: player),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: HarmonixColors.textPrimary, size: 30),
            onPressed: player.closeFullPlayer,
          ),
          const Spacer(),
          const Text(
            'Reproduciendo',
            style: TextStyle(
              color: HarmonixColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: HarmonixColors.textPrimary),
            onPressed: () => _showOptionsSheet(context),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_rounded,
                  color: HarmonixColors.download),
              title: const Text('Descargar para offline'),
              onTap: () async {
                final s = player.currentSong;
                if (s == null) {
                  if (context.mounted) Navigator.pop(context);
                  return;
                }
                // Resolver URL directa vía yt-dlp si no está cacheada.
                String? url = s.streamUrl;
                if (url == null || url.isEmpty) {
                  try {
                    url = await MusicRepository.instance.resolveDirectUrl(s.id);
                  } catch (_) {
                    url = null;
                  }
                }
                if (url == null) {
                  if (context.mounted) Navigator.pop(context);
                  return;
                }
                await DownloadService.instance.download(s, url);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lyrics_rounded,
                  color: HarmonixColors.accent),
              title: const Text('Traducir letras'),
              onTap: () {
                player.toggleTranslation();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded,
                  color: HarmonixColors.textSecondary),
              title: const Text('Compartir'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingBody extends StatelessWidget {
  const _NowPlayingBody({required this.player, required this.song});
  final PlayerProvider player;
  final Song? song;

  @override
  Widget build(BuildContext context) {
    if (song == null) {
      return const Center(
        child: Text('No hay canción reproduciéndose',
            style: TextStyle(color: HarmonixColors.textSecondary)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        if (isLandscape) {
          return Row(
            children: [
              Expanded(
                flex: 4,
                child: _CoverArt(song: song!, size: constraints.maxHeight * 0.8),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SongInfo(song: song!, player: player),
                    const SizedBox(height: 24),
                    _LyricsView(player: player),
                  ],
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _CoverArt(song: song!, size: constraints.maxWidth * 0.72),
              const SizedBox(height: 28),
              _SongInfo(song: song!, player: player),
              const SizedBox(height: 18),
              SizedBox(
                height: 220,
                child: _LyricsView(player: player),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _CoverArt extends StatelessWidget {
  const _CoverArt({required this.song, required this.size});
  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'cover-${song.id}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: HarmonixColors.accent.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: song.thumbnailUrl == null
              ? Container(
                  color: HarmonixColors.surfaceVariant,
                  child: Icon(Icons.music_note_rounded,
                      color: HarmonixColors.accent, size: size * 0.4),
                )
              : CachedNetworkImage(
                  imageUrl: song.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: HarmonixColors.surfaceVariant),
                  errorWidget: (_, __, ___) => Container(
                    color: HarmonixColors.surfaceVariant,
                    child: Icon(Icons.music_note_rounded,
                        color: HarmonixColors.accent, size: size * 0.3),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({required this.song, required this.player});
  final Song song;
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HarmonixColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HarmonixColors.accentBright,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FavoriteButton(
            isFavorite: player.isCurrentFavorite,
            onToggle: player.toggleFavorite,
          ),
        ],
      ),
    );
  }
}

class _LyricsView extends StatelessWidget {
  const _LyricsView({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final lyrics = player.translateLyrics
        ? (player.translatedLyrics.isNotEmpty
            ? player.translatedLyrics
            : player.lyrics)
        : player.lyrics;
    if (lyrics.isEmpty) {
      return const Center(
        child: Text('Letra no disponible',
            style: TextStyle(color: HarmonixColors.textSecondary, fontSize: 13)),
      );
    }
    final active = player.currentLyricIndex;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      itemCount: lyrics.length,
      itemBuilder: (ctx, i) {
        final line = lyrics[i];
        final isActive = i == active;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: isActive
                ? HarmonixColors.accentBright
                : HarmonixColors.textSecondary,
            fontSize: isActive ? 20 : 16,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            height: 1.6,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(line.text),
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.player});
  final PlayerProvider player;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = player.duration.inMilliseconds.toDouble();
    final pos = player.position.inMilliseconds
        .clamp(0, total > 0 ? total.toInt() : 0)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          WavySlider(
            value: pos,
            min: 0,
            max: total > 0 ? total : 1,
            onChanged: (v) => player.seekTo(Duration(milliseconds: v.toInt())),
            height: 38,
            waveAmplitude: 6,
            waveLength: 24,
            waveSpeed: 1.8,
            animateOnPlay: player.isPlaying,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(player.position),
                  style: const TextStyle(
                      color: HarmonixColors.textSecondary, fontSize: 11)),
              Text(_fmt(player.duration),
                  style: const TextStyle(
                      color: HarmonixColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  player.state.shuffleMode
                      ? Icons.shuffle_rounded
                      : Icons.shuffle_outlined,
                  color: player.state.shuffleMode
                      ? HarmonixColors.accentBright
                      : HarmonixColors.textSecondary,
                ),
                onPressed: player.toggleShuffle,
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded,
                    color: HarmonixColors.textPrimary, size: 36),
                onPressed: player.previous,
              ),
              _PlayPauseBig(player: player),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    color: HarmonixColors.textPrimary, size: 36),
                onPressed: player.next,
              ),
              IconButton(
                icon: Icon(
                  player.state.loopMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: player.state.loopMode != LoopMode.off
                      ? HarmonixColors.accentBright
                      : HarmonixColors.textSecondary,
                ),
                onPressed: player.cycleLoop,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AdvancedControls(player: player),
        ],
      ),
    );
  }
}

class _PlayPauseBig extends StatelessWidget {
  const _PlayPauseBig({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: player.isPlaying
          ? Container(
              key: const ValueKey('pause-big'),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [HarmonixColors.accent, HarmonixColors.accentDim],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HarmonixColors.accent.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: player.togglePlay,
                  child: const Padding(
                    padding: EdgeInsets.all(22),
                    child: Icon(Icons.pause_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
            )
          : Container(
              key: const ValueKey('play-big'),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [HarmonixColors.accent, HarmonixColors.accentDim],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HarmonixColors.accent.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: player.togglePlay,
                  child: const Padding(
                    padding: EdgeInsets.all(22),
                    child: Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
            ),
    );
  }
}

class _AdvancedControls extends StatelessWidget {
  const _AdvancedControls({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.speed_rounded,
              color: HarmonixColors.textSecondary),
          onPressed: () => _showSpeedSheet(context),
        ),
        IconButton(
          icon: Icon(
            player.state.skipSilence
                ? Icons.hearing_rounded
                : Icons.hearing_disabled_rounded,
            color: player.state.skipSilence
                ? HarmonixColors.accentBright
                : HarmonixColors.textSecondary,
          ),
          onPressed: () => player.setSkipSilence(!player.state.skipSilence),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded,
              color: HarmonixColors.textSecondary),
          onPressed: () => _showPitchTempoSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up_rounded,
              color: HarmonixColors.textSecondary),
          onPressed: () => _showVolumeSheet(context),
        ),
      ],
    );
  }

  void _showSpeedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Velocidad',
                  style: TextStyle(
                      color: HarmonixColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
            ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map(
              (v) => ListTile(
                title: Text('${v}x'),
                trailing: player.state.speed == v
                    ? const Icon(Icons.check, color: HarmonixColors.accent)
                    : null,
                onTap: () {
                  player.setSpeed(v);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showPitchTempoSheet(BuildContext context) {
    double pitch = player.state.pitch;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pitch',
                    style: TextStyle(
                        color: HarmonixColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Slider(
                  value: pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: pitch.toStringAsFixed(2),
                  onChanged: (v) => setState(() => pitch = v),
                  onChangeEnd: (v) => player.setPitch(v),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVolumeSheet(BuildContext context) {
    double vol = player.state.volume;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Volumen',
                    style: TextStyle(
                        color: HarmonixColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Slider(
                  value: vol,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  onChanged: (v) => setState(() => vol = v),
                  onChangeEnd: (v) => player.setVolume(v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
