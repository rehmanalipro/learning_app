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
  final ProfileController _profileController = Get.find<ProfileController>();
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
    try {
      // ignore: avoid_print
      print('[Profile] Starting image picker with source: $source');
      
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image == null) {
        // ignore: avoid_print
        print('[Profile] Image picker cancelled by user');
        return;
      }

      // ignore: avoid_print
      print('[Profile] Image picker returned path: ${image.path}');
      // ignore: avoid_print
      print('[Profile] Image name: ${image.name}');
      // ignore: avoid_print
      print('[Profile] Image mimeType: ${image.mimeType}');

      // Read file as bytes to verify accessibility
      final bytes = await image.readAsBytes();
      final fileSize = bytes.length;
      
      // ignore: avoid_print
      print('[Profile] Image read successfully, Size: $fileSize bytes');

      if (fileSize > 5 * 1024 * 1024) {
        // 5MB limit
        Get.snackbar(
          'File Too Large',
          'Please select an image smaller than 5MB',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD64545),
          colorText: Colors.white,
        );
        return;
      }

      // Store the XFile path (works with both file paths and content URIs)
      setState(() {
        _imagePath = image.path;
      });
      
      // ignore: avoid_print
      print('[Profile] Image path set successfully: $_imagePath');
      
      Get.snackbar(
        'Image Selected',
        'Image ready to upload. Tap "Save Profile" to upload.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF129C63),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[Profile] Image picker error: $e');
      // ignore: avoid_print
      print('[Profile] Error type: ${e.runtimeType}');
      Get.snackbar(
        'Error',
        'Failed to select image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD64545),
        colorText: Colors.white,
      );
    }
  }

  void _showImageOptions() {
    final palette = context.appPalette;
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: palette.primary),
                title: Text('Choose from Gallery', style: TextStyle(color: palette.text)),
                onTap: () {
                  Get.back();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: palette.primary),
                title: Text('Take Photo', style: TextStyle(color: palette.text)),
                onTap: () {
                  Get.back();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imagePath != null && _imagePath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Get.back();
                    _confirmDeletePhoto();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePhoto() {
    final palette = context.appPalette;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Photo?', style: TextStyle(color: palette.text)),
        content: Text(
          'Are you sure you want to remove your profile photo?',
          style: TextStyle(color: palette.subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              setState(() {
                _imagePath = '';  // Empty string signals removal
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
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
    
    // ignore: avoid_print
    print('[Profile] Starting save profile...');
    // ignore: avoid_print
    print('[Profile] Current _imagePath: $_imagePath');
    
    try {
      final currentProfile = _profileProvider.profileFor(widget.role);
      final existingImagePath = currentProfile.imagePath;
      
      // ignore: avoid_print
      print('[Profile] Existing image path from profile: $existingImagePath');
      
      // Check if user wants to remove photo (empty string)
      final isRemovingPhoto = _imagePath != null && _imagePath!.isEmpty;
      
      // Check if user selected a new local image
      final hasNewLocalImage =
          _imagePath != null &&
          _imagePath!.isNotEmpty &&
          !_imagePath!.startsWith('http');

      // ignore: avoid_print
      print('[Profile] isRemovingPhoto: $isRemovingPhoto');
      // ignore: avoid_print
      print('[Profile] hasNewLocalImage: $hasNewLocalImage');

      String? finalImagePath;
      
      if (isRemovingPhoto) {
        // User wants to remove photo - set to null
        finalImagePath = null;
        // ignore: avoid_print
        print('[Profile] Removing photo');
      } else if (hasNewLocalImage) {
        // ignore: avoid_print
        print('[Profile] Uploading new image from: $_imagePath');
        
        _firebaseService.initialize();
        final currentUid = _firebaseService.currentUser?.uid;
        if (currentUid == null || currentUid.isEmpty) {
          throw Exception('User is not signed in');
        }

        // Show uploading message
        Get.snackbar(
          'Uploading',
          'Uploading profile image...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        // Use XFile for upload (handles both file paths and content URIs)
        try {
          finalImagePath = await _storageService.uploadFile(
            localPath: _imagePath!,
            folder: 'profiles/$currentUid',
            fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          if (finalImagePath == null || finalImagePath.isEmpty) {
            throw Exception('Profile image upload failed - no URL returned');
          }

          // ignore: avoid_print
          print('[Profile] Image uploaded successfully: $finalImagePath');
        } catch (uploadError) {
          // ignore: avoid_print
          print('[Profile] Upload error: $uploadError');
          rethrow;
        }
      } else {
        // Keep existing image path (either from _imagePath or from current profile)
        finalImagePath = _imagePath ?? existingImagePath;
        // ignore: avoid_print
        print('[Profile] Keeping existing image: $finalImagePath');
      }

      // ignore: avoid_print
      print('[Profile] Final image path to save: $finalImagePath');

      // Validate that if we have an HTTP URL, it's properly formatted
      if (finalImagePath != null && 
          finalImagePath.startsWith('http') && 
          !finalImagePath.contains('firebasestorage.googleapis.com')) {
        // ignore: avoid_print
        print('[Profile] Warning: Image path does not look like a Firebase Storage URL');
      }

      try {
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
          imagePath: finalImagePath,
        );
      } catch (updateError) {
        // ignore: avoid_print
        print('[Profile] Update error: $updateError');
        
        // If the error is related to storage and we have an existing image,
        // try again without the image path
        final errorStr = updateError.toString().toLowerCase();
        if ((errorStr.contains('storage') || errorStr.contains('object-not-found') || 
             errorStr.contains('no object exists')) && 
            finalImagePath != null && finalImagePath.startsWith('http')) {
          // ignore: avoid_print
          print('[Profile] Retrying without image path due to storage error');
          
          Get.snackbar(
            'Warning',
            'Your profile photo may be unavailable. Saving profile without photo...',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          
          // Retry without the problematic image path
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
            imagePath: null,  // Remove the problematic image path
          );
          
          if (mounted) {
            setState(() {
              _imagePath = null;  // Clear the image path in UI
            });
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        setState(() {
          _imagePath = finalImagePath;
        });
      }

      // Reload profiles to ensure UI is updated
      await _profileProvider.loadProfiles();

      Get.snackbar(
        'Success',
        isRemovingPhoto 
            ? 'Profile photo removed successfully.'
            : '${widget.role} profile has been saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF129C63),
        colorText: Colors.white,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[Profile Error] Full error: $e');
      // ignore: avoid_print
      print('[Profile Error] Stack trace: ${StackTrace.current}');
      
      // Better error message
      String errorMessage = 'Failed to save profile.';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('file not found') || errorStr.contains('not accessible')) {
        errorMessage = 'Image file not accessible. Please try selecting the image again.';
      } else if (errorStr.contains('object-not-found') || errorStr.contains('no object exists')) {
        errorMessage = 'Could not save profile. Please try uploading a new photo or remove the current one.';
      } else if (errorStr.contains('permission-denied') || errorStr.contains('unauthorized')) {
        errorMessage = 'Permission denied. Please check your account permissions.';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorStr.contains('not signed in')) {
        errorMessage = 'Please log in again to upload images.';
      } else {
        errorMessage = 'Failed to save profile: ${e.toString()}';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD64545),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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
    // Safely handle imagePath - ensure it's a valid string or null
    _imagePath = (profile.imagePath ?? '').trim().isEmpty 
        ? null 
        : profile.imagePath;
    
    // ignore: avoid_print
    print('[Profile Init] Loaded profile with imagePath: $_imagePath');
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
                    onPressed: _isSaving ? null : _confirmDeletePhoto,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Remove current photo',
                      style: TextStyle(color: Colors.red),
                    ),
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
