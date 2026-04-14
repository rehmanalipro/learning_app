import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../providers/firebase_auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;
  bool _minLength = false;

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
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _checkPassword(String value) {
    setState(() {
      _hasUpper = value.contains(RegExp(r'[A-Z]'));
      _hasLower = value.contains(RegExp(r'[a-z]'));
      _hasDigit = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      _minLength = value.length >= 8;
    });
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      Get.snackbar('Validation', 'All fields are required.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (newPass != confirm) {
      Get.snackbar('Mismatch', 'New passwords do not match.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!(_hasUpper && _hasLower && _hasDigit && _hasSpecial && _minLength)) {
      Get.snackbar('Weak password', 'Password does not meet requirements.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final ok = await _authProvider.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );

    if (!mounted) return;

    if (ok) {
      Get.snackbar('Success', 'Your password has been updated.',
          snackPosition: SnackPosition.BOTTOM);
      Get.back();
    } else {
      Get.snackbar('Failed',
          _authProvider.errorMessage.value.isEmpty
              ? 'Could not change password. Check your current password.'
              : _authProvider.errorMessage.value,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _criteriaRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isValid ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: isValid ? Colors.green : Colors.grey, fontSize: 13)),
        ],
      ),
    );
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
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 1.2,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  palette.accent.withValues(alpha: 0.12),
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
                                  color: palette.accent.withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.lock_person_rounded,
                                color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 20),
                          Text('Change Password',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: palette.text)),
                          const SizedBox(height: 6),
                          Text('Update your account password securely.',
                              style: TextStyle(
                                  color: palette.subtext, fontSize: 14),
                              textAlign: TextAlign.center),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PassField(
                                    controller: _currentCtrl,
                                    label: 'Current Password'),
                                const SizedBox(height: 16),
                                _PassField(
                                  controller: _newCtrl,
                                  label: 'New Password',
                                  onChanged: _checkPassword,
                                ),
                                if (_newCtrl.text.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _criteriaRow('Minimum 8 characters', _minLength),
                                  _criteriaRow('Uppercase letter', _hasUpper),
                                  _criteriaRow('Lowercase letter', _hasLower),
                                  _criteriaRow('Number', _hasDigit),
                                  _criteriaRow('Special character', _hasSpecial),
                                ],
                                const SizedBox(height: 16),
                                _PassField(
                                    controller: _confirmCtrl,
                                    label: 'Confirm New Password'),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: Obx(() => ElevatedButton(
                                        onPressed:
                                            _authProvider.isLoading.value
                                                ? null
                                                : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: palette.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _authProvider.isLoading.value
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text('Update Password',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                      )),
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

class _PassField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const _PassField(
      {required this.controller, required this.label, this.onChanged});

  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
