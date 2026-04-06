import 'package:flutter/material.dart';

import '../../core/theme/app_theme_helper.dart';

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

    return AppBar(
      automaticallyImplyLeading: leading == null,
      leading: leading,
      centerTitle: centerTitle,
      elevation: 0,
      toolbarHeight: height,
      backgroundColor: Colors.transparent,
      foregroundColor: palette.inverseText,
      actions: actions,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.inverseText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.inverseText.withValues(alpha: 0.92),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (tertiary != null && tertiary!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              tertiary!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.softCard,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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
