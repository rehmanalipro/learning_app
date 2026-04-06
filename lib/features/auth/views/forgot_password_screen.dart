import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../providers/firebase_auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prefill = Get.arguments as String?;
    if (prefill != null && prefill.trim().isNotEmpty) {
      _emailController.text = prefill.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Validation',
        'Email address enter karein.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await _authProvider.resetPassword(email);
    if (!mounted) return;

    if (ok) {
      Get.snackbar(
        'Email sent',
        'Password reset email bhej di gayi hai.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
      return;
    }

    Get.snackbar(
      'Reset failed',
      _authProvider.errorMessage.value.isEmpty
          ? 'Password reset nahi ho saka.'
          : _authProvider.errorMessage.value,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Forgot Password',
        subtitle: 'Receive reset email',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            maxWidth: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.announcementCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Apna registered email likhein. Firebase aap ko reset password email bhej dega.',
                    style: TextStyle(
                      color: palette.inverseText.withValues(alpha: 0.92),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.primary, width: 1.2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: _authProvider.isLoading.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.inverseText,
                      ),
                      child: Text(
                        _authProvider.isLoading.value
                            ? 'Sending...'
                            : 'Send Reset Email',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
