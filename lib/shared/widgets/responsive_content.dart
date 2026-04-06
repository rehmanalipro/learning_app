import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding,
  });

  EdgeInsets _responsivePadding(BuildContext context) {
    if (padding is EdgeInsets) {
      return padding as EdgeInsets;
    }

    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    if (width >= 800) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 18);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? _responsivePadding(context),
          child: child,
        ),
      ),
    );
  }
}
