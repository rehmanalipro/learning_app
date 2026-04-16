import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/class_binding_service.dart';
import '../../features/auth/providers/firebase_auth_provider.dart';
import '../../core/theme/app_theme_helper.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/school/views/school_info_screen.dart';
import '../../routes/app_routes.dart';
import '../widgets/adaptive_layout.dart';

class MainDrawer extends StatelessWidget {
  final String role;

  const MainDrawer({super.key, required this.role});
  // This method shows a confirmation dialog when the user attempts to log out.18 to 118
  Future<bool?> _showLogoutConfirmation() {
    final dialogContext = Get.context;
    if (dialogContext == null) {
      return Future.value(false);
    }
    final palette = dialogContext.appPalette;

    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: palette.softCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.logout_outlined, color: palette.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Are you sure you want to log out of the app?',
                style: TextStyle(
                  color: palette.subtext,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.text,
                        side: BorderSide(color: palette.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('No'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.inverseText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(FirebaseAuthProvider authProvider) async {
    Get.back();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final shouldLogout = await _showLogoutConfirmation() ?? false;
    if (!shouldLogout) return;

    if (Get.isRegistered<ClassBindingService>()) {
      Get.find<ClassBindingService>().clear();
    }
    await authProvider.signOut(role: role);
    Get.offAllNamed(AppRoutes.choose);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final profileProvider = Get.find<ProfileProvider>();
    final authProvider = Get.find<FirebaseAuthProvider>();
    final drawerWidth = context.adaptiveValue<double>(
      compact: context.isExtraNarrowViewport
          ? MediaQuery.sizeOf(context).width * 0.92
          : MediaQuery.sizeOf(context).width * 0.86,
      medium: 320,
      expanded: 340,
      wide: 380,
    );

    return Drawer(
      width: drawerWidth.clamp(280.0, 380.0).toDouble(),
      child: Column(
        children: [
          Obx(() {
            final profile = profileProvider.profileFor(role);
            final imagePath = profile.imagePath;
            return Container(
              height: context.isCompactViewport ? 170 : 180,
              width: double.infinity,
              color: palette.drawerHeader,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: palette.surface,
                    backgroundImage: imagePath == null || imagePath.isEmpty
                        ? null
                        : imagePath.startsWith('http')
                        ? NetworkImage(imagePath)
                        : FileImage(File(imagePath)) as ImageProvider,
                    child: imagePath == null || imagePath.isEmpty
                        ? Icon(
                            Icons.person_outline,
                            size: 32,
                            color: palette.primary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: palette.subtext),
                    ),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: Container(
              color: palette.drawerBody,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerTile(
                    icon: Icons.account_circle_outlined,
                    label: 'My Profile',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.profile, arguments: {'role': role});
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.school_outlined,
                    label: 'Profile of School',
                    onTap: () {
                      Get.back();
                      Get.toNamed(
                        AppRoutes.schoolInfo,
                        arguments: {
                          'role': role,
                          'type': SchoolInfoType.schoolProfile,
                        },
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.apartment_outlined,
                    label: 'Profile of publication',
                    onTap: () {
                      Get.back();
                      Get.toNamed(
                        AppRoutes.schoolInfo,
                        arguments: {
                          'role': role,
                          'type': SchoolInfoType.publicationProfile,
                        },
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.contact_phone_outlined,
                    label: 'Emergency contacts',
                    onTap: () {
                      Get.back();
                      Get.toNamed(
                        AppRoutes.schoolInfo,
                        arguments: {
                          'role': role,
                          'type': SchoolInfoType.emergencyContacts,
                        },
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.smart_toy_outlined,
                    label: 'AI Assistant',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.chatbot);
                    },
                  ),
                  if (role.toLowerCase() == 'principal')
                    _DrawerTile(
                      icon: Icons.how_to_reg_outlined,
                      label: 'Student Admissions',
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.studentAdmissions);
                      },
                    ),
                  if (role.toLowerCase() == 'principal')
                    _DrawerTile(
                      icon: Icons.badge_outlined,
                      label: 'Teacher Accounts',
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.teacherAccounts);
                      },
                    ),
                  _DrawerTile(
                    icon: Icons.lock_reset_outlined,
                    label: 'Change Password',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.changePassword);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Get.back();
                      Get.toNamed(
                        AppRoutes.schoolInfo,
                        arguments: {
                          'role': role,
                          'type': SchoolInfoType.settings,
                        },
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.logout_outlined,
                    label: 'Logout',
                    onTap: () async {
                      await _handleLogout(authProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _DrawerTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return ListTile(
      leading: Icon(icon, color: palette.inverseText, size: 20),
      title: Text(
        label,
        style: TextStyle(color: palette.inverseText, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
