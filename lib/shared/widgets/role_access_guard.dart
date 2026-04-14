import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/providers/firebase_auth_provider.dart';
import '../../routes/app_routes.dart';

class RoleAccessGuard extends StatefulWidget {
  final String requiredRole;
  final Widget child;

  const RoleAccessGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  @override
  State<RoleAccessGuard> createState() => _RoleAccessGuardState();
}

class _RoleAccessGuardState extends State<RoleAccessGuard> {
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();

  bool _isChecking = true;
  bool _isAllowed = false;

  @override
  void initState() {
    super.initState();
    _verifyAccess();
  }

  Future<void> _verifyAccess() async {
    final userData = await _authProvider.loadCurrentUserData();
    final savedRole = (userData?['role'] as String? ?? '').trim();

    if (!mounted) return;

    if (savedRole.toLowerCase() == widget.requiredRole.toLowerCase()) {
      setState(() {
        _isAllowed = true;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isAllowed = false;
      _isChecking = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lowerRole = savedRole.toLowerCase();
      final fallbackRoute = lowerRole == 'teacher'
          ? AppRoutes.teacher
          : lowerRole == 'principal'
          ? AppRoutes.principal
          : lowerRole == 'student'
          ? AppRoutes.student
          : AppRoutes.choose;

      if (savedRole.isEmpty) {
        await _authProvider.signOut();
      }

      Get.snackbar(
        'Access denied',
        'This section is only for ${widget.requiredRole}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(
        fallbackRoute,
        arguments: savedRole.isEmpty ? null : savedRole,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAllowed) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return widget.child;
  }
}
