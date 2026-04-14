import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../controllers/profile_controller.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String role;

  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _profileController = Get.put(
    ProfileController(),
    permanent: true,
  );
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _picker = ImagePicker();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();

  bool get _isStudentRole => widget.role.toLowerCase() == 'student';

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _imagePath;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    setState(() {
      _imagePath = image.path;
    });
  }

  void _showImageOptions() {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imagePath != null && _imagePath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Get.back();
                  setState(() {
                    _imagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _imageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final hasNewLocalImage =
          _imagePath != null &&
          _imagePath!.isNotEmpty &&
          !_imagePath!.startsWith('http');

      String? uploadedImageUrl;
      if (hasNewLocalImage) {
        _firebaseService.initialize();
        final currentUid = _firebaseService.currentUser?.uid;
        if (currentUid == null || currentUid.isEmpty) {
          throw Exception('User is not signed in');
        }

        uploadedImageUrl = await _storageService.uploadFile(
          localPath: _imagePath!,
          folder: 'profiles/$currentUid',
        );

        if (uploadedImageUrl == null) {
          throw Exception('Profile image upload failed');
        }
      }

      final resolvedImagePath = uploadedImageUrl ?? _imagePath;
      final currentProfile = _profileProvider.profileFor(widget.role);

      await _profileController.updateProfile(
        role: widget.role,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        className: currentProfile.className,
        section: currentProfile.section,
        programName: _isStudentRole ? currentProfile.programName : null,
        admissionNo: _isStudentRole ? currentProfile.admissionNo : null,
        rollNumber: _isStudentRole ? currentProfile.rollNumber : null,
        linkedStudentProfileId: _isStudentRole
            ? currentProfile.linkedStudentProfileId
            : null,
        imagePath: resolvedImagePath,
      );

      if (mounted) {
        setState(() {
          _imagePath = resolvedImagePath;
        });
      }

      Get.snackbar(
        'Profile updated',
        '${widget.role} profile has been saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to save profile image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final profile = _profileController.profileFor(widget.role);
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _imagePath = profile.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isTeacher = widget.role.toLowerCase() == 'teacher';
    final isStudent = widget.role.toLowerCase() == 'student';
    final classBinding = Get.isRegistered<ClassBindingService>()
        ? Get.find<ClassBindingService>()
        : null;

    return Scaffold(
      appBar: AppScreenHeader(
        title: '${widget.role} Profile',
        subtitle: 'Manage personal information and preferences',
      ),
      backgroundColor: palette.scaffold,
      body: AppRefreshScope(
        onRefresh: _profileProvider.loadProfiles,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ResponsiveContent(
            maxWidth: 760,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showImageOptions,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: palette.softCard,
                    backgroundImage: _imageProvider(_imagePath),
                    child: _imagePath == null
                        ? Icon(
                            Icons.person_outline,
                            size: 46,
                            color: palette.primary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.role.toLowerCase() == 'principal'
                      ? 'Principal can manage personal profile photo and details here.'
                      : isTeacher
                      ? 'Teacher can manage this profile.'
                      : 'Student can manage profile image and details here.',
                  style: const TextStyle(color: Colors.black54),
                ),
                if (_imagePath != null && _imagePath!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _imagePath = null;
                            });
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete current photo'),
                  ),
                ],
                const SizedBox(height: 24),
                _ProfileField(controller: _nameController, label: 'Full Name'),
                const SizedBox(height: 14),
                _ProfileField(controller: _emailController, label: 'Email'),
                const SizedBox(height: 14),
                _ProfileField(controller: _phoneController, label: 'Phone'),
                if (isTeacher && classBinding != null) ...[
                  const SizedBox(height: 14),
                  Obx(
                    () => _ReadOnlyInfoCard(
                      items: {
                        'Class': classBinding.className.value.isNotEmpty
                            ? classBinding.className.value
                            : '-',
                        'Section': classBinding.section.value.isNotEmpty
                            ? classBinding.section.value
                            : '-',
                        'Subject': classBinding.subject.value.isNotEmpty
                            ? classBinding.subject.value
                            : '-',
                      },
                    ),
                  ),
                ],
                if (isStudent) ...[
                  const SizedBox(height: 14),
                  _ReadOnlyInfoCard(
                    items: {
                      'Admission No':
                          _profileProvider
                              .profileFor(widget.role)
                              .admissionNo ??
                          '-',
                      'Roll No':
                          _profileProvider.profileFor(widget.role).rollNumber ??
                          '-',
                      'Program':
                          _profileProvider
                              .profileFor(widget.role)
                              .programName ??
                          '-',
                      'Class':
                          _profileProvider.profileFor(widget.role).className ??
                          '-',
                      'Section':
                          _profileProvider.profileFor(widget.role).section ??
                          '-',
                    },
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.inverseText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Profile'),
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

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _ProfileField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.subtext),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ReadOnlyInfoCard extends StatelessWidget {
  final Map<String, String> items;

  const _ReadOnlyInfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: items.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.key,
                style: TextStyle(fontSize: 11, color: palette.subtext),
              ),
              const SizedBox(height: 2),
              Text(
                entry.value,
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
