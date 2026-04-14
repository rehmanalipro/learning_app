import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/animated_page_wrapper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';

class ChooseOptionScreen extends StatelessWidget {
  const ChooseOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Choose Your Option',
        subtitle: 'Select your role to continue',
      ),
      body: AnimatedPageWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveContent(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      AnimatedListItem(
                        index: 0,
                        child: _RoleCard(
                          icon: Icons.school_outlined,
                          label: 'Student',
                          color: palette.primary,
                          onTap: () => Get.toNamed(AppRoutes.login, arguments: 'Student'),
                        ),
                      ),
                      AnimatedListItem(
                        index: 1,
                        child: _RoleCard(
                          icon: Icons.chair_outlined,
                          label: 'Teacher',
                          color: palette.primary,
                          onTap: () => Get.toNamed(AppRoutes.login, arguments: 'Teacher'),
                        ),
                      ),
                      AnimatedListItem(
                        index: 2,
                        child: _RoleCard(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Principal',
                          color: palette.primary,
                          onTap: () => Get.toNamed(AppRoutes.login, arguments: 'Principal'),
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
        width: 156,
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
