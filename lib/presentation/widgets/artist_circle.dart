import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/models/artist.dart';

/// Círculo de artista para el carrusel horizontal en Home.
class ArtistCircle extends StatelessWidget {
  const ArtistCircle({super.key, required this.artist, this.onTap});
  final Artist artist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: HarmonixColors.accent.withValues(alpha: 0.4),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: HarmonixColors.accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: (artist.thumbnailUrl == null ||
                        artist.thumbnailUrl!.isEmpty)
                    ? Container(
                        width: 76,
                        height: 76,
                        color: HarmonixColors.surfaceVariant,
                        child: const Icon(Icons.person,
                            color: HarmonixColors.accent, size: 32),
                      )
                    : CachedNetworkImage(
                        imageUrl: artist.thumbnailUrl!,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: HarmonixColors.surfaceVariant,
                          width: 76,
                          height: 76,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: HarmonixColors.surfaceVariant,
                          width: 76,
                          height: 76,
                          child: const Icon(Icons.person,
                              color: HarmonixColors.accent),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HarmonixColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
