import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../routes/app_routes.dart';
import '../providers/firebase_auth_provider.dart';

/// Production-ready forgot password with Firebase link + OTP verification
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final TextEditingController _emailController = TextEditingController();

  String _role = '';
  bool _isOtpSent = false;
  String _verifiedEmail = '';

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _emailController.text = args.trim();
    } else if (args is Map<String, dynamic>) {
      final prefill = (args['identifier'] as String? ?? '').trim();
      _role = (args['role'] as String? ?? '').trim();
      if (prefill.isNotEmpty) {
        _emailController.text = prefill;
      }
    }
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
    ).drive(Tween(begin: const Offset(0, 0.12), end: Offset.zero));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      Get.snackbar(
        'Validation',
        'Please enter your user ID or email.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Step 1: Send Firebase password reset link
    final ok = await _authProvider.resetPassword(identifier, roleHint: _role);

    if (!ok) {
      Get.snackbar(
        'Reset failed',
        _authProvider.errorMessage.value.isEmpty
            ? 'Unable to send reset link. Please try again.'
            : _authProvider.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Step 2: Send OTP for additional verification
    final resolvedEmail = await _authProvider.resolveLoginIdentifier(
      identifier,
      roleHint: _role,
    );

    final otp = await _authProvider.sendEmailOtp(
      email: resolvedEmail,
      mode: 'forgotPassword',
    );

    setState(() {
      _isOtpSent = true;
      _verifiedEmail = resolvedEmail;
    });

    Get.snackbar(
      'Reset Link Sent',
      'Check your email for the password reset link. Also verify with OTP: $otp',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 8),
    );
  }

  Future<void> _verifyAndReset() async {
    // Navigate to OTP screen for verification
    final result = await Get.toNamed(
      AppRoutes.otp,
      arguments: {
        'email': _verifiedEmail,
        'mode': 'forgotPassword',
        'role': _role,
      },
    );

    if (result == true) {
      // OTP verified, now user can use Firebase reset link
      Get.offAllNamed(AppRoutes.login, arguments: {'role': _role});
      Get.snackbar(
        'Success',
        'Please check your email and click the reset link to complete password change.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
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
            top: -size.width * 0.4,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 1.4,
              height: size.width * 1.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
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
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [palette.accent, palette.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isOtpSent
                                ? 'Check your email and verify with OTP'
                                : 'Enter your user ID or email to receive a reset link',
                            style: TextStyle(
                              color: palette.subtext,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(24),
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
                                if (!_isOtpSent) ...[
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText:
                                          _role.toLowerCase() == 'principal'
                                          ? 'Principal Email'
                                          : 'User ID or Email',
                                      prefixIcon: const Icon(
                                        Icons.lock_person_outlined,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: palette.border,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: palette.primary,
                                          width: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: Obx(
                                      () => ElevatedButton.icon(
                                        onPressed: _authProvider.isLoading.value
                                            ? null
                                            : _sendResetLink,
                                        icon: const Icon(Icons.email_outlined),
                                        label: Text(
                                          _authProvider.isLoading.value
                                              ? 'Sending...'
                                              : 'Send Reset Link & OTP',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: palette.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: palette.softCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: palette.border),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.mark_email_read,
                                          color: palette.primary,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Reset link sent to:',
                                          style: TextStyle(
                                            color: palette.subtext,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _verifiedEmail,
                                          style: TextStyle(
                                            color: palette.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '1. Check your email inbox\n2. Click the reset link\n3. Verify with OTP below',
                                          style: TextStyle(
                                            color: palette.text,
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: _verifyAndReset,
                                      icon: const Icon(Icons.verified_user),
                                      label: const Text(
                                        'Verify with OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: palette.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: () => Get.offAllNamed(
                              AppRoutes.login,
                              arguments: {'role': _role},
                            ),
                            icon: const Icon(Icons.arrow_back_ios, size: 14),
                            label: const Text('Back to Login'),
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
