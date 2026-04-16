import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/loading_dots.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../models/student_profile_model.dart';
import '../providers/student_profile_provider.dart';

class PrincipalStudentAdmissionsScreen extends StatefulWidget {
  const PrincipalStudentAdmissionsScreen({super.key});

  @override
  State<PrincipalStudentAdmissionsScreen> createState() =>
      _PrincipalStudentAdmissionsScreenState();
}

class _PrincipalStudentAdmissionsScreenState
    extends State<PrincipalStudentAdmissionsScreen> {
  final StudentProfileProvider _provider = Get.find<StudentProfileProvider>();
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();

  final _formKey = GlobalKey<FormState>();
  final _admissionNoController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _programController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _searchController = TextEditingController();

  final List<String> _classes = const [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];
  final List<String> _sections = const ['A', 'B', 'C'];
  final List<String> _genders = const ['Male', 'Female', 'Other'];
  final List<String> _statuses = const ['active', 'inactive'];

  String _selectedClass = '1';
  String _selectedSection = 'A';
  String _selectedGender = 'Male';
  String _selectedStatus = 'active';
  int _activeTab = 0; // 0 = Form, 1 = List

  String _filterClass = 'All';
  String _filterSection = 'All';
  String _filterGender = 'All';
  String _searchQuery = '';
  String _principalName = 'Principal';
  String? _editingProfileId;
  Map<String, String>? _lastIssuedCredentials;
  bool _isSavingAdmission = false;

  StudentProfileModel? get _editingProfile => _editingProfileId == null
      ? null
      : _provider.studentProfiles.firstWhereOrNull(
          (item) => item.id == _editingProfileId,
        );

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      await _provider.loadAll();
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Admissions unavailable',
          'Student admission records load nahi ho sake. Firestore rules deploy karne ki zarurat ho sakti hai.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    final userData = await _authProvider.loadCurrentUserData();
    if (!mounted) return;
    setState(() {
      _principalName = (userData?['name'] as String? ?? '').trim().isEmpty
          ? 'Principal'
          : (userData?['name'] as String).trim();
    });
  }

  @override
  void dispose() {
    _admissionNoController.dispose();
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _programController.dispose();
    _rollNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initialDate =
        DateTime.tryParse(_dobController.text.trim()) ?? DateTime(2015, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
  }

  Future<void> _saveAdmission() async {
    if (_isSavingAdmission) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final now = DateTime.now().toIso8601String();
    final existing = _editingProfile;
    final profile = StudentProfileModel(
      id: _editingProfileId ?? _provider.createProfileId(),
      admissionNo: _provider.normalizeAdmissionNo(_admissionNoController.text),
      fullName: _fullNameController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      dateOfBirth: _provider.normalizeDate(_dobController.text.trim()),
      gender: _selectedGender,
      studentEmail: _emailController.text.trim().toLowerCase(),
      phone: _phoneController.text.trim(),
      className: _selectedClass,
      section: _selectedSection,
      rollNumber: _rollNumberController.text.trim(),
      programName: _programController.text.trim(),
      status: _selectedStatus,
      generatedUserId: existing?.generatedUserId ?? '',
      linkedUserUid: existing?.linkedUserUid ?? '',
      linkedUserEmail: existing?.linkedUserEmail ?? '',
      credentialsIssuedAt: existing?.credentialsIssuedAt ?? '',
      createdBy: existing?.createdBy ?? _principalName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() {
      _isSavingAdmission = true;
    });

    try {
      await _provider.upsertStudentProfile(profile);

      if (!profile.isLinked) {
        final credentials = await _authProvider.provisionStudentAccount(
          profile: profile,
        );
        _rememberIssuedCredentials(
          fullName: profile.fullName,
          userId: credentials.userId,
          password: credentials.password,
          email: credentials.email,
        );
        if (!mounted) return;
        await _showCredentialsDialog(
          fullName: profile.fullName,
          userId: credentials.userId,
          password: credentials.password,
          email: credentials.email,
        );
        if (!mounted) return;
        _resetForm();
        _activeTab = 1;
        Get.snackbar(
          'Saved',
          'Student admission saved and login generated successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      _resetForm();
      _activeTab = 1;
      Get.snackbar(
        'Saved',
        'Student admission record has been updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Admission save failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAdmission = false;
        });
      }
    }
  }

  Future<void> _generateCredentialsForProfile(
    StudentProfileModel profile,
  ) async {
    if (_isSavingAdmission) return;
    setState(() {
      _isSavingAdmission = true;
    });
    try {
      final credentials = await _authProvider.provisionStudentAccount(
        profile: profile,
      );
      _rememberIssuedCredentials(
        fullName: profile.fullName,
        userId: credentials.userId,
        password: credentials.password,
        email: credentials.email,
      );
      if (!mounted) return;
      await _showCredentialsDialog(
        fullName: profile.fullName,
        userId: credentials.userId,
        password: credentials.password,
        email: credentials.email,
      );
      if (!mounted) return;
      Get.snackbar(
        'Saved',
        'Student login generated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Credential generation failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAdmission = false;
        });
      }
    }
  }

  void _rememberIssuedCredentials({
    required String fullName,
    required String userId,
    required String password,
    required String email,
  }) {
    setState(() {
      _lastIssuedCredentials = {
        'fullName': fullName,
        'userId': userId,
        'password': password,
        'email': email,
      };
    });
  }

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    Get.snackbar(
      'Copied',
      '$label copied successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _showCredentialsDialog({
    required String fullName,
    required String userId,
    required String password,
    required String email,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Student Login Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$fullName ka account create ho gaya hai.'),
            const SizedBox(height: 12),
            _credentialRow('User ID', userId),
            const SizedBox(height: 8),
            _credentialRow('Password', password),
            const SizedBox(height: 8),
            _credentialRow('Email', email),
            const SizedBox(height: 12),
            const Text(
              'Student is generated login se sign in kare ga aur baad mein Forgot Password se apna password reset kar sakta hai.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _copyText(
              'All credentials',
              'User ID: $userId\nPassword: $password\nEmail: $email',
            ),
            child: const Text('Copy All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editAdmission(StudentProfileModel profile) {
    setState(() {
      _editingProfileId = profile.id;
      _admissionNoController.text = profile.admissionNo;
      _fullNameController.text = profile.fullName;
      _fatherNameController.text = profile.fatherName;
      _dobController.text = profile.dateOfBirth;
      _emailController.text = profile.studentEmail;
      _phoneController.text = profile.phone;
      _programController.text = profile.programName;
      _rollNumberController.text = profile.rollNumber;
      _selectedClass = profile.className;
      _selectedSection = profile.section;
      _selectedGender = profile.gender.isEmpty
          ? _genders.first
          : profile.gender;
      _selectedStatus = profile.status;
      _activeTab = 0;
    });
  }

  void _resetForm() {
    setState(() {
      _editingProfileId = null;
      _admissionNoController.clear();
      _fullNameController.clear();
      _fatherNameController.clear();
      _dobController.clear();
      _emailController.clear();
      _phoneController.clear();
      _programController.clear();
      _rollNumberController.clear();
      _selectedClass = _classes.first;
      _selectedSection = _sections.first;
      _selectedGender = _genders.first;
      _selectedStatus = _statuses.first;
    });
  }

  List<StudentProfileModel> _filteredAdmissions(
    List<StudentProfileModel> items,
  ) {
    return items
        .where((profile) {
          final matchesClass =
              _filterClass == 'All' || profile.className == _filterClass;
          final matchesSection =
              _filterSection == 'All' || profile.section == _filterSection;
          final matchesGender =
              _filterGender == 'All' || profile.gender == _filterGender;
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch =
              query.isEmpty ||
              profile.fullName.toLowerCase().contains(query) ||
              profile.admissionNo.toLowerCase().contains(query) ||
              profile.rollNumber.toLowerCase().contains(query) ||
              profile.phone.toLowerCase().contains(query) ||
              profile.studentEmail.toLowerCase().contains(query) ||
              profile.generatedUserId.toLowerCase().contains(query);
          return matchesClass &&
              matchesSection &&
              matchesGender &&
              matchesSearch;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: const AppScreenHeader(
        title: 'Student Admissions',
        subtitle: 'Principal-controlled student identity records',
      ),
      body: AppRefreshScope(
        onRefresh: _provider.loadAll,
        child: Obx(() {
          final admissions = _provider.studentProfiles.toList(growable: false);
          final filtered = _filteredAdmissions(admissions);

          return Column(
            children: [
              // Fixed Tab Bar
              Container(
                color: palette.surfaceAlt,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ResponsiveContent(
                  maxWidth: 1100,
                  child: _buildTopTabs(
                    palette,
                    leftLabel: 'Admission Form',
                    rightLabel: 'Students List',
                  ),
                ),
              ),
              // Fixed Search Bar (only in list view)
              if (_activeTab == 1)
                Container(
                  color: palette.surfaceAlt,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ResponsiveContent(
                    maxWidth: 1100,
                    child: _buildCompactSearchBar(palette, admissions.length, filtered.length),
                  ),
                ),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: ResponsiveContent(
                    maxWidth: 1100,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_activeTab == 0) ...[
                          _buildGuideCard(palette),
                          const SizedBox(height: 12),
                          if (_lastIssuedCredentials != null) ...[
                            _buildLatestCredentialsCard(palette),
                            const SizedBox(height: 12),
                          ],
                          _buildFormCard(palette),
                        ] else ...[
                          if (_provider.isLoading.value)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (filtered.isEmpty)
                            _buildEmptyCard(palette)
                          else
                            _buildStudentTable(palette, filtered),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGuideCard(AppThemePalette palette) {
    final totalStudents = _provider.studentProfiles.length;
    final maleCount = _provider.studentProfiles
        .where((item) => item.gender == 'Male')
        .length;
    final femaleCount = _provider.studentProfiles
        .where((item) => item.gender == 'Female')
        .length;
    final linkedCount = _provider.studentProfiles
        .where((item) => item.isLinked)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admission Master Flow',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Principal yahan student ka complete record save kare ga, student email add kare ga, aur system isi screen se strong password aur unique user ID generate kare ga. Student ko alag signup ki zarurat nahi hogi.',
            style: TextStyle(color: palette.subtext, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(palette, 'Total', '$totalStudents'),
              _infoChip(palette, 'Male', '$maleCount'),
              _infoChip(palette, 'Female', '$femaleCount'),
              _infoChip(palette, 'Linked', '$linkedCount', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestCredentialsCard(AppThemePalette palette) {
    final creds = _lastIssuedCredentials!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Generated Login',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            creds['fullName'] ?? '',
            style: TextStyle(
              color: palette.subtext,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _credentialRow('User ID', creds['userId'] ?? ''),
          const SizedBox(height: 8),
          _credentialRow('Password', creds['password'] ?? ''),
          const SizedBox(height: 8),
          _credentialRow('Email', creds['email'] ?? ''),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyText('User ID', creds['userId'] ?? ''),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy User ID'),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyText('Password', creds['password'] ?? ''),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy Password'),
              ),
              ElevatedButton.icon(
                onPressed: () => _copyText(
                  'All credentials',
                  'User ID: ${creds['userId'] ?? ''}\nPassword: ${creds['password'] ?? ''}\nEmail: ${creds['email'] ?? ''}',
                ),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Copy All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabs(
    AppThemePalette palette, {
    required String leftLabel,
    required String rightLabel,
  }) {
    Widget tabItem({required int index, required String label}) {
      final isSelected = _activeTab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _activeTab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? palette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? palette.inverseText : palette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          tabItem(index: 0, label: leftLabel),
          const SizedBox(width: 8),
          tabItem(index: 1, label: rightLabel),
        ],
      ),
    );
  }

  Widget _buildFormCard(AppThemePalette palette) {
    final isLinkedEditing = _editingProfile?.isLinked ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _editingProfileId == null
                        ? 'Create Admission Record'
                        : 'Edit Admission Record',
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_editingProfileId != null)
                  TextButton(
                    onPressed: _resetForm,
                    child: const Text('Cancel Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _admissionNoController,
              label: 'Admission No',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _fullNameController,
              label: 'Student Name',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _fatherNameController,
              label: 'Father Name',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Gender',
                    value: _selectedGender,
                    items: _genders,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGender = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Student Email',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLinkedEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter valid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(controller: _programController, label: 'Program'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Class',
                    value: _selectedClass,
                    items: _classes,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedClass = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Section',
                    value: _selectedSection,
                    items: _sections,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSection = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _rollNumberController,
                    label: 'Roll Number',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Status',
                    value: _selectedStatus,
                    items: _statuses,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Save ke baad system 8 se 16 characters ke darmiyan strong password aur unique student user ID generate kare ga.',
              style: TextStyle(
                color: palette.subtext,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingAdmission ? null : _saveAdmission,
                icon: _isSavingAdmission
                    ? const LoadingDots(color: Colors.white, size: 7)
                    : Icon(
                        isLinkedEditing
                            ? Icons.save_outlined
                            : Icons.vpn_key_outlined,
                      ),
                label: Text(
                  _isSavingAdmission
                      ? 'Saving...'
                      : isLinkedEditing
                      ? 'Update Admission Record'
                      : 'Save Admission + Generate Login',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSearchBar(
    AppThemePalette palette,
    int total,
    int showing,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search by name, admission, roll, email...',
                hintStyle: TextStyle(fontSize: 12),
                prefixIcon: Icon(Icons.search, size: 18),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$showing/$total',
            style: TextStyle(
              color: palette.subtext,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showFilterMenu(palette),
            icon: Icon(Icons.filter_list, color: palette.primary, size: 20),
            tooltip: 'Filters',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu(AppThemePalette palette) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown(
                label: 'Class',
                value: _filterClass,
                items: const ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
                onChanged: (value) {
                  if (value != null) setState(() => _filterClass = value);
                },
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'Section',
                value: _filterSection,
                items: const ['All', 'A', 'B', 'C'],
                onChanged: (value) {
                  if (value != null) setState(() => _filterSection = value);
                },
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'Gender',
                value: _filterGender,
                items: const ['All', 'Male', 'Female', 'Other'],
                onChanged: (value) {
                  if (value != null) setState(() => _filterGender = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterClass = 'All';
                _filterSection = 'All';
                _filterGender = 'All';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(AppThemePalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        'No admission records found for the selected filters.',
        style: TextStyle(color: palette.subtext),
      ),
    );
  }

  Widget _buildStudentTable(
    AppThemePalette palette,
    List<StudentProfileModel> students,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: palette.softCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 25,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Adm',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Roll',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Class',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 45),
              ],
            ),
          ),
          // Table Rows
          ...students.asMap().entries.map((entry) {
            final index = entry.key;
            final profile = entry.value;
            return _buildStudentRow(palette, index + 1, profile);
          }),
        ],
      ),
    );
  }

  Widget _buildStudentRow(
    AppThemePalette palette,
    int serialNo,
    StudentProfileModel profile,
  ) {
    return InkWell(
      onTap: () => _showStudentDetails(profile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: palette.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              child: Text(
                '$serialNo',
                style: TextStyle(
                  color: palette.subtext,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.fullName,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.isLinked)
                    Container(
                      margin: const EdgeInsets.only(left: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        '✓',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                profile.admissionNo,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                profile.rollNumber,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${profile.className}-${profile.section}',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 10,
                ),
              ),
            ),
            SizedBox(
              width: 45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!profile.isLinked)
                    IconButton(
                      onPressed: _isSavingAdmission
                          ? null
                          : () => _generateCredentialsForProfile(profile),
                      tooltip: 'Gen',
                      icon: Icon(
                        Icons.vpn_key_outlined,
                        color: palette.primary,
                        size: 13,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                    ),
                  IconButton(
                    onPressed: () => _editAdmission(profile),
                    tooltip: 'Edit',
                    icon: Icon(
                      Icons.edit_outlined,
                      color: palette.primary,
                      size: 13,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(StudentProfileModel profile) {
    final palette = context.appPalette;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Admission No', profile.admissionNo),
              _detailRow('Roll Number', profile.rollNumber),
              _detailRow('Class', '${profile.className}-${profile.section}'),
              _detailRow('Father Name', profile.fatherName),
              _detailRow('Date of Birth', profile.dateOfBirth),
              _detailRow('Gender', profile.gender),
              _detailRow('Email', profile.studentEmail),
              _detailRow('Phone', profile.phone),
              if (profile.programName.isNotEmpty)
                _detailRow('Program', profile.programName),
              if (profile.generatedUserId.isNotEmpty)
                _detailRow('User ID', profile.generatedUserId),
              _detailRow('Status', profile.status),
              _detailRow(
                'Account',
                profile.isLinked ? 'Linked ✓' : 'Not Linked',
              ),
            ],
          ),
        ),
        actions: [
          if (!profile.isLinked)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _generateCredentialsForProfile(profile);
              },
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('Generate Login'),
            ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editAdmission(profile);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(growable: false),
    );
  }

  Widget _infoChip(
    AppThemePalette palette,
    String label,
    String value, {
    bool highlight = false,
    bool warning = false,
  }) {
    final backgroundColor = warning
        ? const Color(0xFFFFF4E5)
        : highlight
        ? palette.softCard
        : palette.surfaceAlt;
    final foregroundColor = warning ? const Color(0xFFB96A00) : palette.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _credentialRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: SelectableText(
            '$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: value.trim().isEmpty
              ? null
              : () => _copyText(label, value),
          icon: const Icon(Icons.copy_outlined),
          tooltip: 'Copy $label',
        ),
      ],
    );
  }
}
