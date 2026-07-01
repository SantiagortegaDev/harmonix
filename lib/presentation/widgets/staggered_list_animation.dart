import 'package:flutter/material.dart';

/// Wrapper que aplica staggered fade + slide cuando el item entra en pantalla.
///
/// Pensado para usarse dentro de listas verticales o grids. [index] controla
/// el retardo escalonado entre items.
class StaggeredItem extends StatefulWidget {
  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 420),
  });

  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Duration duration;

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    final delay = Duration(
        milliseconds:
            (widget.delayPerItem.inMilliseconds * widget.index).clamp(0, 600));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Versión para AnimatedList: inserta/remueve items con animación.
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.animation,
    required this.child,
    this.slideOffset = const Offset(0, 0.15),
  });

  final Animation<double> animation;
  final Widget child;
  final Offset slideOffset;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: slideOffset, end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}
