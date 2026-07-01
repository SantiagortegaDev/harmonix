import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/presentation/widgets/loading_skeleton.dart';

/// Fila de canción para listas (Recientes, Favoritos, Descargas, etc.).
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.index,
    this.onTap,
    this.onPlay,
    this.trailing,
    this.isActive = false,
  });

  final Song song;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final Widget? trailing;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive
                        ? HarmonixColors.accentBright
                        : HarmonixColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SongCover(song: song, size: 44, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? HarmonixColors.accentBright
                            : HarmonixColors.textPrimary,
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
              const SizedBox(width: 8),
              Text(
                song.durationLabel,
                style: const TextStyle(
                  color: HarmonixColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              trailing ??
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: HarmonixColors.textSecondary, size: 20),
                    onPressed: () {},
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
