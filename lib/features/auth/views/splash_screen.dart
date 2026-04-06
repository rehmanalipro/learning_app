import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../theme/providers/app_theme_provider.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.autoNavigate = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  Future<void> _navigateNext() async {
    final authProvider = Get.find<FirebaseAuthProvider>();
    final appThemeProvider = Get.find<AppThemeProvider>();
    final userData = await authProvider.loadCurrentUserData();
    final role = (userData?['role'] as String? ?? '').trim();

    if (!mounted) return;

    if (role.isEmpty) {
      Get.offAllNamed(AppRoutes.choose);
      return;
    }

    appThemeProvider.setCurrentRole(role);
    final route = role.toLowerCase() == 'teacher'
        ? AppRoutes.teacher
        : role.toLowerCase() == 'principal'
            ? AppRoutes.principal
            : AppRoutes.student;
    Get.offAllNamed(route, arguments: role);
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate && !Get.testMode) {
      _navigationTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _navigateNext();
        }
      });
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: Stack(
        children: [
          Positioned(
            left: -width * 0.35,
            top: -180,
            child: Container(
              width: width * 1.7,
              height: 310,
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(260),
                  bottomRight: Radius.circular(260),
                ),
              ),
            ),
          ),
          Positioned(
            right: -width * 0.35,
            bottom: -190,
            child: Container(
              width: width * 1.7,
              height: 330,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(260),
                  topRight: Radius.circular(260),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    size: 78,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  'School Management System',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Attendance, Grades, Timetable, and More',
                  style: TextStyle(fontSize: 16, color: palette.subtext),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                Text(
                  'Powered by PR Rehman Ali',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
