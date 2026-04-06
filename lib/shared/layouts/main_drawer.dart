import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme_helper.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/school/views/school_info_screen.dart';
import '../../routes/app_routes.dart';

class MainDrawer extends StatelessWidget {
  final String role;

  const MainDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final profileProvider = Get.find<ProfileProvider>();

    return Drawer(
      child: Column(
        children: [
          Obx(() {
            final profile = profileProvider.profileFor(role);
            return Container(
              height: 180,
              width: double.infinity,
              color: palette.drawerHeader,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: palette.surface,
                    backgroundImage: profile.imagePath == null
                        ? null
                        : profile.imagePath!.startsWith('http')
                            ? NetworkImage(profile.imagePath!)
                            : FileImage(File(profile.imagePath!)) as ImageProvider,
                    child: profile.imagePath == null
                        ? Icon(
                            Icons.person_outline,
                            size: 32,
                            color: palette.primary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    profile.email,
                    style: TextStyle(fontSize: 12, color: palette.subtext),
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
                    onTap: () {
                      Get.back();
                      Get.offAllNamed(AppRoutes.choose);
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
