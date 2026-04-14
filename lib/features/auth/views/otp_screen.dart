import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../routes/app_routes.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/firebase_auth_provider.dart';

/// OTP screen arguments:
/// {
///   'email': String,
///   'mode': 'signup' | 'forgotPassword',
///   'role': String (for signup),
/// }
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const bool _allowOtpBypass = false; // ✅ Production mode enabled
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();

  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
      

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  Map<String, dynamic> get _args {
    final args = Get.arguments;
    return args is Map<String, dynamic> ? args : <String, dynamic>{};
  }
  String get _email => _args['email'] as String? ?? '';
  String get _mode => _args['mode'] as String? ?? 'signup';
  String get _role => _args['role'] as String? ?? 'Student';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: const Offset(0, 0.12), end: Offset.zero));
    _animCtrl.forward();
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (final n in _focusNodes) { n.dispose(); }
    for (final c in _controllers) { c.dispose(); }
    _animCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    debugPrint('[OTP] Verify tapped mode=$_mode role=$_role code=$_otp bypass=$_allowOtpBypass');
    if (_otp.length < 4) {
      Get.snackbar('Incomplete', 'Please enter the 4-digit code.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      if (_allowOtpBypass) {
        debugPrint('[OTP] Bypass active');
        if (_mode == 'signup') {
          final route = _role.toLowerCase() == 'teacher'
              ? AppRoutes.teacher
              : _role.toLowerCase() == 'principal'
                  ? AppRoutes.principal
                  : AppRoutes.student;
          debugPrint('[OTP] Navigating to route=$route');
          Get.offAllNamed(route, arguments: _role);
        } else {
          debugPrint('[OTP] Navigating to login from bypass');
          Get.offAllNamed(AppRoutes.login, arguments: _role);
          Get.snackbar(
            'Verified',
            'OTP check temporary skip ki gayi hai.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return;
      }

      // Verify email OTP via Firebase Auth
      final ok = await _authProvider.verifyEmailOtp(
        email: _email,
        otp: _otp,
        mode: _mode,
      );
      debugPrint('[OTP] verifyEmailOtp result=$ok');

      if (!ok) {
        Get.snackbar('Invalid code',
            'The code you entered is incorrect or has expired.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (_mode == 'signup') {
        // Profile load karo before navigation
        if (Get.isRegistered<ProfileProvider>()) {
          await Get.find<ProfileProvider>().loadProfiles();
        }
        final route = _role.toLowerCase() == 'teacher'
            ? AppRoutes.teacher
            : _role.toLowerCase() == 'principal'
                ? AppRoutes.principal
                : AppRoutes.student;
        Get.offAllNamed(route, arguments: _role);
      } else {
        // forgotPassword - go to login
        Get.offAllNamed(AppRoutes.login, arguments: _role);
        Get.snackbar('Verified',
            'Identity confirmed. You can now sign in.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      await _authProvider.sendEmailOtp(email: _email, mode: _mode);
      _startCooldown();
      Get.snackbar('Code sent', 'A new verification code has been sent.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: Stack(
        children: [
          Positioned(
            top: -size.width * 0.35,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 1.3,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  palette.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [palette.primary, palette.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.primary.withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mark_email_read_rounded,
                                color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Verify Your Email',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We sent a 4-digit code to',
                            style: TextStyle(
                                color: palette.subtext, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Card
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // 4 digit boxes
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(4, (i) {
                                    return _OtpBox(
                                      controller: _controllers[i],
                                      focusNode: _focusNodes[i],
                                      onChanged: (val) {
                                        if (val.isNotEmpty && i < 3) {
                                          _focusNodes[i + 1].requestFocus();
                                        }
                                        if (val.isEmpty && i > 0) {
                                          _focusNodes[i - 1].requestFocus();
                                        }
                                        setState(() {});
                                      },
                                    );
                                  }),
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isVerifying ? null : _verify,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: palette.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isVerifying
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Verify Code',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Resend
                                TextButton(
                                  onPressed: (_resendCooldown > 0 || _isResending)
                                      ? null
                                      : _resend,
                                  child: _isResending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Text(
                                          _resendCooldown > 0
                                              ? 'Resend code in ${_resendCooldown}s'
                                              : 'Resend Code',
                                          style: TextStyle(
                                            color: _resendCooldown > 0
                                                ? palette.subtext
                                                : palette.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: Get.back,
                            icon: const Icon(Icons.arrow_back_ios, size: 14),
                            label: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      width: 60,
      height: 64,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: palette.text,
        ),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.primary, width: 2),
          ),
          filled: true,
          fillColor: palette.surfaceAlt,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
