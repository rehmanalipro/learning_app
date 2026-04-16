import 'package:flutter/material.dart';

enum AppViewport { compact, medium, expanded, wide }

extension AdaptiveLayoutContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  AppViewport get viewport {
    final width = screenWidth;
    if (width < 600) return AppViewport.compact;
    if (width < 1024) return AppViewport.medium;
    if (width < 1440) return AppViewport.expanded;
    return AppViewport.wide;
  }

  bool get isCompactViewport => viewport == AppViewport.compact;
  bool get isMediumViewport => viewport == AppViewport.medium;
  bool get isExpandedViewport =>
      viewport == AppViewport.expanded || viewport == AppViewport.wide;
  bool get isExtraNarrowViewport => screenWidth < 360;

  T adaptiveValue<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? wide,
  }) {
    switch (viewport) {
      case AppViewport.compact:
        return compact;
      case AppViewport.medium:
        return medium ?? expanded ?? wide ?? compact;
      case AppViewport.expanded:
        return expanded ?? wide ?? medium ?? compact;
      case AppViewport.wide:
        return wide ?? expanded ?? medium ?? compact;
    }
  }

  EdgeInsets adaptivePagePadding({
    EdgeInsets? compact,
    EdgeInsets? medium,
    EdgeInsets? expanded,
    EdgeInsets? wide,
  }) {
    final defaultCompact = isExtraNarrowViewport
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

    return adaptiveValue<EdgeInsets>(
      compact: compact ?? defaultCompact,
      medium: medium ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      expanded:
          expanded ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      wide: wide ?? const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
    );
  }

  int adaptiveColumns({
    int compact = 1,
    int medium = 2,
    int expanded = 4,
    int wide = 5,
  }) {
    return adaptiveValue<int>(
      compact: compact,
      medium: medium,
      expanded: expanded,
      wide: wide,
    );
  }
}
