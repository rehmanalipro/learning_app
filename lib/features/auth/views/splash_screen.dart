import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../theme/providers/app_theme_provider.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  final bool autoNavigate;
  const SplashScreen({super.key, this.autoNavigate = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  late final AnimationController _orbitCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.elasticOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _logoFade = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.easeIn,
    ).drive(Tween(begin: 0.0, end: 1.0));

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textFade = CurvedAnimation(
      parent: _textCtrl,
      curve: Curves.easeIn,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = CurvedAnimation(
      parent: _textCtrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: const Offset(0, 0.35), end: Offset.zero));

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _shimmerAnim = CurvedAnimation(
      parent: _shimmerCtrl,
      curve: Curves.easeInOut,
    );

    _logoCtrl.forward().then((_) => _textCtrl.forward());

    if (widget.autoNavigate && !Get.testMode) {
      _navTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) _navigateNext();
      });
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _orbitCtrl.dispose();
    _shimmerCtrl.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    try {
      final authProvider = Get.find<FirebaseAuthProvider>();
      final appThemeProvider = Get.find<AppThemeProvider>();

      User? firebaseUser =
          authProvider.currentUser.value ??
          authProvider.firebaseService.currentUser;

      if (firebaseUser == null) {
        try {
          firebaseUser = await authProvider.firebaseService.auth
              .authStateChanges()
              .first
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          firebaseUser = null;
        }
      }

      if (!mounted) return;
      if (firebaseUser == null) {
        Get.offAllNamed(AppRoutes.choose);
        return;
      }

      final userData =
          authProvider.peekCurrentUserData() ??
          await authProvider.loadCurrentUserData();
      final role = (userData?['role'] as String? ?? '').trim();

      if (!mounted) return;
      if (role.isEmpty) {
        await authProvider.signOut();
        Get.offAllNamed(AppRoutes.choose);
        return;
      }

      appThemeProvider.setCurrentSession(role: role, userId: firebaseUser.uid);
      Get.find<ClassBindingService>().loadFromUserData(userData!);
      final route = role.toLowerCase() == 'teacher'
          ? AppRoutes.teacher
          : role.toLowerCase() == 'principal'
          ? AppRoutes.principal
          : AppRoutes.student;
      Get.offAllNamed(route, arguments: role);

      unawaited(
        _warmUpSignedInSession(
          role: role,
          className: userData['className'] as String?,
          section: userData['section'] as String?,
        ),
      );
    } catch (_) {
      try {
        await Get.find<FirebaseAuthProvider>().signOut();
      } catch (_) {}
      if (mounted) Get.offAllNamed(AppRoutes.choose);
    }
  }

  Future<void> _warmUpSignedInSession({
    required String role,
    String? className,
    String? section,
  }) async {
    try {
      if (Get.isRegistered<ProfileProvider>()) {
        await Get.find<ProfileProvider>().loadProfiles();
      }
    } catch (_) {}

    try {
      await Get.find<FcmService>().subscribeToRoleTopics(
        role: role,
        className: className,
        section: section,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const blue = Color(0xFF1E56CF);
    const green = Color(0xFF2FC0A7);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (_, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(blue, const Color(0xFF1A3FA0), _shimmerAnim.value)!,
                Color.lerp(const Color(0xFF1A7FC1), green, _shimmerAnim.value)!,
                Color.lerp(green, blue, _shimmerAnim.value * 0.6)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -size.width * 0.3,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.85,
                  height: size.width * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -size.width * 0.3,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.75,
                  height: size.width * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _orbitCtrl,
                            builder: (_, _) => CustomPaint(
                              size: const Size(260, 260),
                              painter: _OrbitTextPainter(
                                angle: _orbitCtrl.value * 2 * math.pi,
                                text: 'SCHOOL MANAGEMENT SYSTEM  •  ',
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 32,
                                      offset: const Offset(0, 14),
                                    ),
                                    BoxShadow(
                                      color: green.withValues(alpha: 0.35),
                                      blurRadius: 22,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 62,
                                  color: blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            Text(
                              'Attendance · Grades · Timetable',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 13,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 36),
                            _LoadingDots(),
                            const SizedBox(height: 28),
                            Text(
                              'Powered by PR Rehman Ali',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitTextPainter extends CustomPainter {
  final double angle;
  final String text;
  final Color color;

  _OrbitTextPainter({
    required this.angle,
    required this.text,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final chars = text.characters.toList();
    final step = 2 * math.pi / chars.length;

    for (int i = 0; i < chars.length; i++) {
      final charAngle = angle + i * step;
      final x = center.dx + radius * math.cos(charAngle - math.pi / 2);
      final y = center.dy + radius * math.sin(charAngle - math.pi / 2);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(charAngle);

      final tp = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_OrbitTextPainter old) => old.angle != angle;
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_ctrl.value - i / 3) % 1.0);
          final scale = math.sin(t * math.pi).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: 0.5 + scale * 0.5,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.4 + scale * 0.6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
