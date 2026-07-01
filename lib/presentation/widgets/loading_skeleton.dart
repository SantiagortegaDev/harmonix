import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/models/song.dart';

/// Skeleton animado (shimmer) para usar mientras carga contenido.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(
              HarmonixColors.surface,
              HarmonixColors.surfaceVariant,
              t * 0.7,
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton de una tarjeta de canción en grid.
class SongCardSkeleton extends StatelessWidget {
  const SongCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingSkeleton(
          height: 140,
          borderRadius: 16,
        ),
        const SizedBox(height: 8),
        const LoadingSkeleton(height: 12, width: 110),
        const SizedBox(height: 6),
        const LoadingSkeleton(height: 10, width: 70),
      ],
    );
  }
}

/// Skeleton para listas horizontales.
class PlaylistCardSkeleton extends StatelessWidget {
  const PlaylistCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HarmonixColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingSkeleton(height: 100, borderRadius: 16),
          SizedBox(height: 12),
          LoadingSkeleton(height: 14, width: 140),
          SizedBox(height: 6),
          LoadingSkeleton(height: 11, width: 90),
        ],
      ),
    );
  }
}

/// Imagen de portada con placeholder shimmer mientras carga.
class SongCover extends StatelessWidget {
  const SongCover({
    super.key,
    required this.song,
    this.size = 140,
    this.borderRadius = 16,
  });
  final Song song;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (song.thumbnailUrl == null || song.thumbnailUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: HarmonixColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.music_note_rounded,
            color: HarmonixColors.accent, size: size * 0.4),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: song.thumbnailUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => LoadingSkeleton(
          height: size,
          borderRadius: borderRadius,
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          color: HarmonixColors.surfaceVariant,
          child: Icon(Icons.broken_image_outlined,
              color: HarmonixColors.textSecondary, size: size * 0.3),
        ),
      ),
    );
  }
}
