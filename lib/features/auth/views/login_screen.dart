import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../theme/providers/app_theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final AppThemeProvider _appThemeProvider = Get.find<AppThemeProvider>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String get _role {
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) return args;
    if (args is Map<String, dynamic>) {
      final mappedRole = args['role'] as String?;
      if (mappedRole != null && mappedRole.isNotEmpty) return mappedRole;
    }
    return 'Student';
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: const Offset(0, 0.08), end: Offset.zero));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final requestedRole = _role.trim();
    final identifier = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (identifier.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Validation',
        'User ID or email and password are required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = await _authProvider.signIn(
      email: identifier,
      password: password,
      roleHint: requestedRole,
    );
    if (!ok) {
      Get.snackbar(
        'Login failed',
        _authProvider.errorMessage.value.isEmpty
            ? 'Unable to sign in. Please try again.'
            : _authProvider.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final userData = await _authProvider.loadCurrentUserData();
    final savedRole = (userData?['role'] as String? ?? '').trim();
    if (savedRole.isEmpty || userData == null) {
      await _authProvider.signOut();
      Get.snackbar(
        'Profile missing',
        requestedRole.toLowerCase() == 'principal'
            ? 'Principal account mila lekin us ka Firestore profile document nahi mila. Principal signup app mein band hai, is liye existing principal document ko repair karna hoga.'
            : 'Account role/profile not found. Please contact the administrator.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (savedRole.toLowerCase() != requestedRole.toLowerCase()) {
      await _authProvider.signOut();
      Get.snackbar(
        'Access denied',
        'Yeh account $savedRole ke liye registered hai, $requestedRole portal ke liye nahi.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    _profileProvider.ensureProfile(savedRole);
    final currentUid =
        _authProvider.currentUser.value?.uid ??
        _authProvider.firebaseService.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      _appThemeProvider.setCurrentSession(role: savedRole, userId: currentUid);
    } else {
      _appThemeProvider.setCurrentRole(savedRole);
    }
    Get.find<ClassBindingService>().loadFromUserData(userData!);

    final route = savedRole.toLowerCase() == 'teacher'
        ? AppRoutes.teacher
        : savedRole.toLowerCase() == 'principal'
        ? AppRoutes.principal
        : AppRoutes.student;
    Get.offAllNamed(route, arguments: savedRole);

    unawaited(
      _completeLoginSetup(
        role: savedRole,
        className: userData['className'] as String?,
        section: userData['section'] as String?,
      ),
    );
  }

  Future<void> _completeLoginSetup({
    required String role,
    String? className,
    String? section,
  }) async {
    try {
      await _profileProvider.loadProfiles();
    } catch (_) {}

    try {
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().subscribeToRoleTopics(
          role: role,
          className: className,
          section: section,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.scaffold,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [palette.primary, palette.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attendance • Grades • Timetable',
                        style: TextStyle(
                          color: palette.subtext,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue your journey',
                        style: TextStyle(color: palette.subtext, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      // User ID / email field
                      _IconField(
                        controller: _emailCtrl,
                        hint: _role.toLowerCase() == 'student' ||
                                _role.toLowerCase() == 'teacher'
                            ? 'User ID or Email'
                            : 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      // Password field
                      _IconField(
                        controller: _passCtrl,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: true,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Get.toNamed(
                            AppRoutes.forgotPassword,
                            arguments: {
                              'identifier': _emailCtrl.text.trim(),
                              'role': _role,
                            },
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Sign In button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Obx(
                          () => ElevatedButton.icon(
                            onPressed: _authProvider.isLoading.value
                                ? null
                                : _login,
                            icon: _authProvider.isLoading.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded, size: 20),
                            label: Text(
                              _authProvider.isLoading.value
                                  ? 'Signing in...'
                                  : 'Sign In',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_role.toLowerCase() == 'student')
                        Text(
                          'Student account principal admission screen se create hota hai. User ID aur password principal provide kare ga.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.subtext,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        )
                      else if (_role.toLowerCase() == 'teacher')
                        Text(
                          'Teacher account principal management screen se create hota hai. Principal aap ko user ID ya email aur password provide kare ga.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.subtext,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        )
                      else if (_role.toLowerCase() == 'principal')
                        Text(
                          'Principal access managed hai. Yahan sirf existing principal account login kare ga. New principal signup app se disabled hai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.subtext,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New to School App? ',
                              style: TextStyle(color: palette.subtext),
                            ),
                            GestureDetector(
                              onTap: () => Get.toNamed(
                                AppRoutes.register,
                                arguments: _role,
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable field with leading icon - screenshot style
class _IconField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;

  const _IconField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_IconField> createState() => _IconFieldState();
}

class _IconFieldState extends State<_IconField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscured,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: palette.subtext),
          prefixIcon: Icon(widget.icon, color: palette.subtext, size: 20),
          suffixIcon: widget.obscure
              ? IconButton(
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: palette.subtext,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
