import 'package:flutter/material.dart';

import '../../core/theme/app_theme_helper.dart';
import 'adaptive_layout.dart';

class AppScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String? tertiary;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double height;

  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.tertiary,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.height = 92,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final compact = context.isCompactViewport;
    final titleWidth = (MediaQuery.sizeOf(context).width - 132)
        .clamp(160.0, 680.0)
        .toDouble();

    return AppBar(
      automaticallyImplyLeading: leading == null,
      leading: leading,
      centerTitle: centerTitle,
      elevation: 0,
      toolbarHeight: height,
      backgroundColor: Colors.transparent,
      foregroundColor: palette.inverseText,
      actions: actions,
      title: SizedBox(
        width: titleWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.inverseText,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.inverseText.withValues(alpha: 0.92),
                  fontSize: compact ? 10 : 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (tertiary != null && tertiary!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                tertiary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.softCard,
                  fontSize: compact ? 9.5 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primary, palette.accent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
        ),
      ),
    );
  }
}
