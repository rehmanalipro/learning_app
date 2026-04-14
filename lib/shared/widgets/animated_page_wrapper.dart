import 'package:flutter/material.dart';

/// Wraps a screen body with a fade+slide entrance animation.
/// Use this as the body of any Scaffold for consistent page transitions.
class AnimatedPageWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<AnimatedPageWrapper> createState() => _AnimatedPageWrapperState();
}

class _AnimatedPageWrapperState extends State<AnimatedPageWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: const Offset(0, 0.04), end: Offset.zero));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
