import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';

/// Botón de favorito con animación de pulso.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 28,
    this.activeColor = HarmonixColors.favorite,
  });

  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color activeColor;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _controller.value = 1.0;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isFavorite) {
      _controller.forward(from: 0.85);
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller.drive(CurveTween(curve: Curves.elasticOut)),
      child: IconButton(
        icon: Icon(
          widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
          color: widget.isFavorite ? widget.activeColor : HarmonixColors.textSecondary,
          size: widget.size,
        ),
        onPressed: _handleTap,
      ),
    );
  }
}
