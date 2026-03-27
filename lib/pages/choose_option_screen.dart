import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';

class ChooseOptionScreen extends StatelessWidget {
  const ChooseOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -width * 0.35,
            top: -180,
            child: Container(
              width: width * 1.7,
              height: 320,
              decoration: const BoxDecoration(
                color: Color(0xFF00BFA5),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(260),
                  bottomLeft: Radius.circular(260),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 26),
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF00BFA5),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.school,
                              color: Color(0xFF1E88E5),
                              size: 55,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Creative Reader\'s',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Publication',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Choose your option',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoleCard(
                          icon: Icons.school_outlined,
                          label: 'Student',
                          color: const Color(0xFF1E88E5),
                          onTap: () => Get.toNamed(
                            AppRoutes.login,
                            arguments: 'Student',
                          ),
                        ),
                        const SizedBox(width: 18),
                        _RoleCard(
                          icon: Icons.chair_outlined,
                          label: 'Teacher',
                          color: const Color(0xFF1E88E5),
                          onTap: () => Get.toNamed(
                            AppRoutes.login,
                            arguments: 'Teacher',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _RoleCard(
                      icon: Icons.person_outline,
                      label: 'Guest',
                      color: const Color(0xFF1E88E5),
                      onTap: () => Get.toNamed(AppRoutes.guest),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 42),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
