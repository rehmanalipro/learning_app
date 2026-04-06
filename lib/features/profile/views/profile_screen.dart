import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/firebase_storage_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../controllers/profile_controller.dart';
import '../../school/providers/school_data_provider.dart';
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
  final SchoolDataProvider _schoolDataProvider = Get.find<SchoolDataProvider>();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _picker = ImagePicker();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final List<String> _classes = const ['1', '2', '3', '4', '5'];
  final List<String> _sections = const ['A', 'B', 'C'];

  bool get _isStudentRole => widget.role.toLowerCase() == 'student';

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _programController;
  String? _selectedClass;
  String? _selectedSection;
  String? _imagePath;

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
    final uploadedImageUrl = _imagePath == null
        ? null
        : _imagePath!.startsWith('http')
            ? _imagePath
            : await _storageService.uploadFile(
                localPath: _imagePath!,
                folder: 'profiles/${widget.role.toLowerCase()}',
              );

    await _profileController.updateProfile(
      role: widget.role,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      className: _selectedClass,
      section: _selectedSection,
      programName: _isStudentRole ? _programController.text.trim() : null,
      imagePath: uploadedImageUrl ?? _imagePath,
    );

    if (widget.role.toLowerCase() == 'principal') {
      await _schoolDataProvider.updateSchoolImage(uploadedImageUrl ?? _imagePath);
    }

    Get.snackbar(
      'Profile updated',
      '${widget.role} profile has been saved.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void initState() {
    super.initState();
    final profile = _profileController.profileFor(widget.role);
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _programController = TextEditingController(text: profile.programName ?? '');
    _selectedClass = profile.className ?? '3';
    _selectedSection = profile.section ?? 'A';
    _imagePath = profile.imagePath;

    if (widget.role.toLowerCase() == 'principal' &&
        _schoolDataProvider.schoolData.value.schoolImagePath != null) {
      _imagePath = _schoolDataProvider.schoolData.value.schoolImagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _programController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isTeacher = widget.role.toLowerCase() == 'teacher';
    final isStudent = widget.role.toLowerCase() == 'student';

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
              isTeacher
                  ? 'Teacher can manage this profile.'
                  : 'Student can manage profile image and details here.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _ProfileField(controller: _nameController, label: 'Full Name'),
            const SizedBox(height: 14),
            _ProfileField(controller: _emailController, label: 'Email'),
            const SizedBox(height: 14),
            _ProfileField(controller: _phoneController, label: 'Phone'),
            if (isStudent) ...[
              const SizedBox(height: 14),
              _ProfileField(controller: _programController, label: 'Program'),
              const SizedBox(height: 14),
              _ProfileDropdownField(
                label: 'Class',
                value: _selectedClass!,
                items: _classes,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedClass = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _ProfileDropdownField(
                label: 'Section',
                value: _selectedSection!,
                items: _sections,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedSection = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.inverseText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Profile'),
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

class _ProfileDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ProfileDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
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
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(growable: false),
    );
  }
}
