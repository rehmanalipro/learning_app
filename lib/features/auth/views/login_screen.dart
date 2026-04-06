import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../theme/providers/app_theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final AppThemeProvider _appThemeProvider = Get.find<AppThemeProvider>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String get _role => (Get.arguments as String?) ?? 'Student';

  @override
  void initState() {
    super.initState();
    final profile = _profileProvider.profileFor(_role);
    _emailController.text = profile.email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Validation',
        'Email aur password required hain.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await _authProvider.signIn(email: email, password: password);
    if (!ok) {
      Get.snackbar(
        'Login failed',
        _authProvider.errorMessage.value.isEmpty
            ? 'Login nahi ho saka.'
            : _authProvider.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final userData = await _authProvider.loadCurrentUserData();
    final savedRole = (userData?['role'] as String? ?? '').trim();
    if (savedRole.isEmpty) {
      Get.snackbar(
        'Role missing',
        'Is account ka role Firestore me nahi mila.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (savedRole.toLowerCase() != _role.toLowerCase()) {
      await _authProvider.signOut();
      Get.snackbar(
        'Wrong role',
        'Ye account $savedRole ke liye hai, $_role ke liye nahi.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _profileProvider.ensureProfile(savedRole);
    _appThemeProvider.setCurrentRole(savedRole);

    final route = savedRole.toLowerCase() == 'teacher'
        ? AppRoutes.teacher
        : savedRole.toLowerCase() == 'principal'
            ? AppRoutes.principal
            : AppRoutes.student;

    Get.offNamed(route, arguments: savedRole);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.scaffold,
      resizeToAvoidBottomInset: false,
      appBar: AppScreenHeader(
        title: '$_role Login',
        subtitle: 'Sign in with Firebase Auth',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            maxWidth: 560,
            child: Column(
              children: [
                const SizedBox(height: 6),
                _LoginField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _LoginField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: _authProvider.isLoading.value ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _authProvider.isLoading.value ? 'Logging in...' : 'Login',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Get.toNamed(
                    AppRoutes.forgotPassword,
                    arguments: _emailController.text.trim(),
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: palette.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('If you haven\'t account, '),
                    TextButton(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.register, arguments: _role),
                      child: Text(
                        'Create your account',
                        style: TextStyle(color: palette.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                ),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
