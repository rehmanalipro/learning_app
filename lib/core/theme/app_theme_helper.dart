import 'package:flutter/material.dart';

class AppThemePalette {
  final bool isDark;

  const AppThemePalette(this.isDark);

  Color get primary => const Color(0xFF1E56CF);
  Color get accent => isDark ? const Color(0xFF14B8A6) : const Color(0xFF2FC0A7);
  Color get scaffold => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get surface => isDark ? const Color(0xFF111827) : Colors.white;
  Color get surfaceAlt => isDark ? const Color(0xFF1F2937) : const Color(0xFFF4F7FB);
  Color get softCard => isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF7F3);
  Color get border => isDark ? const Color(0xFF334155) : const Color(0xFFD8E1F5);
  Color get text => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF202020);
  Color get subtext => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF5B6472);
  Color get inverseText => Colors.white;
  Color get announcementCard => isDark ? const Color(0xFF1D4ED8) : const Color(0xFF1E56CF);
  Color get drawerHeader => isDark ? const Color(0xFF334155) : const Color(0xFFD8D8D8);
  Color get drawerBody => isDark ? const Color(0xFF1D4ED8) : const Color(0xFF1E4CC8);
}

extension AppThemeHelper on BuildContext {
  AppThemePalette get appPalette => AppThemePalette(Theme.of(this).brightness == Brightness.dark);
}
