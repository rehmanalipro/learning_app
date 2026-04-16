import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/loading_dots.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../models/teacher_profile_model.dart';
import '../providers/teacher_profile_provider.dart';

class PrincipalTeacherAccountsScreen extends StatefulWidget {
  const PrincipalTeacherAccountsScreen({super.key});

  @override
  State<PrincipalTeacherAccountsScreen> createState() =>
      _PrincipalTeacherAccountsScreenState();
}

class _PrincipalTeacherAccountsScreenState
    extends State<PrincipalTeacherAccountsScreen> {
  final TeacherProfileProvider _provider = Get.find<TeacherProfileProvider>();
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _subjectController = TextEditingController();
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
  final List<String> _statuses = const ['active', 'inactive'];

  String _selectedClass = '1';
  String _selectedSection = 'A';
  String _selectedStatus = 'active';
  bool _isClassTeacher = false;
  String _filterClass = 'All';
  String _filterSection = 'All';
  String _filterStatus = 'All';
  String _searchQuery = '';
  int _activeTab = 0;
  String _principalName = 'Principal';
  String? _editingProfileId;
  Map<String, String>? _lastIssuedCredentials;
  bool _isSavingTeacher = false;

  TeacherProfileModel? get _editingProfile => _editingProfileId == null
      ? null
      : _provider.teacherProfiles.firstWhereOrNull(
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
          'Teacher accounts unavailable',
          e.toString(),
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

  Future<void> _saveTeacher() async {
    if (_isSavingTeacher) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final now = DateTime.now().toIso8601String();
    final existing = _editingProfile;
    final profile = TeacherProfileModel(
      id: _editingProfileId ?? _provider.createProfileId(),
      fullName: _nameController.text.trim(),
      teacherEmail: _emailController.text.trim().toLowerCase(),
      phone: _phoneController.text.trim(),
      employeeId: _provider.normalizeEmployeeId(_employeeIdController.text),
      department: _departmentController.text.trim(),
      className: _selectedClass,
      section: _selectedSection,
      subject: _subjectController.text.trim(),
      status: _selectedStatus,
      isClassTeacher: _isClassTeacher,
      generatedUserId: existing?.generatedUserId ?? '',
      linkedUserUid: existing?.linkedUserUid ?? '',
      linkedUserEmail: existing?.linkedUserEmail ?? '',
      credentialsIssuedAt: existing?.credentialsIssuedAt ?? '',
      createdBy: existing?.createdBy ?? _principalName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() {
      _isSavingTeacher = true;
    });

    try {
      await _provider.upsertTeacherProfile(profile);
      if (!profile.isLinked) {
        final credentials = await _authProvider.provisionTeacherAccount(
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
          'Teacher record saved and login generated successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _resetForm();
      _activeTab = 1;
      Get.snackbar(
        'Saved',
        'Teacher account record has been updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Teacher save failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTeacher = false;
        });
      }
    }
  }

  Future<void> _generateCredentialsForProfile(
    TeacherProfileModel profile,
  ) async {
    if (_isSavingTeacher) return;
    setState(() {
      _isSavingTeacher = true;
    });
    try {
      final credentials = await _authProvider.provisionTeacherAccount(
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
        'Teacher login generated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Teacher credential generation failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTeacher = false;
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
        title: const Text('Teacher Login Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$fullName ka teacher account create ho gaya hai.'),
            const SizedBox(height: 12),
            _credentialRow('User ID', userId),
            const SizedBox(height: 8),
            _credentialRow('Password', password),
            const SizedBox(height: 8),
            _credentialRow('Email', email),
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

  void _editTeacher(TeacherProfileModel profile) {
    setState(() {
      _editingProfileId = profile.id;
      _nameController.text = profile.fullName;
      _emailController.text = profile.teacherEmail;
      _phoneController.text = profile.phone;
      _employeeIdController.text = profile.employeeId;
      _departmentController.text = profile.department;
      _subjectController.text = profile.subject;
      _selectedClass = profile.className;
      _selectedSection = profile.section;
      _selectedStatus = profile.status;
      _isClassTeacher = profile.isClassTeacher;
      _activeTab = 0;
    });
  }

  void _resetForm() {
    setState(() {
      _editingProfileId = null;
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _employeeIdController.clear();
      _departmentController.clear();
      _subjectController.clear();
      _selectedClass = _classes.first;
      _selectedSection = _sections.first;
      _selectedStatus = _statuses.first;
      _isClassTeacher = false;
    });
  }

  List<TeacherProfileModel> _filteredTeachers(List<TeacherProfileModel> items) {
    return items
        .where((profile) {
          final matchesClass =
              _filterClass == 'All' || profile.className == _filterClass;
          final matchesSection =
              _filterSection == 'All' || profile.section == _filterSection;
          final matchesStatus =
              _filterStatus == 'All' || profile.status == _filterStatus;
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch =
              query.isEmpty ||
              profile.fullName.toLowerCase().contains(query) ||
              profile.teacherEmail.toLowerCase().contains(query) ||
              profile.employeeId.toLowerCase().contains(query) ||
              profile.subject.toLowerCase().contains(query) ||
              profile.generatedUserId.toLowerCase().contains(query);
          return matchesClass &&
              matchesSection &&
              matchesStatus &&
              matchesSearch;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _subjectController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: const AppScreenHeader(
        title: 'Teacher Accounts',
        subtitle: 'Principal-controlled teacher login management',
      ),
      body: AppRefreshScope(
        onRefresh: _provider.loadAll,
        child: Obx(() {
          final teachers = _provider.teacherProfiles.toList(growable: false);
          final filtered = _filteredTeachers(teachers);
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
                    leftLabel: 'Teacher Form',
                    rightLabel: 'Teachers List',
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
                    child: _buildCompactSearchBar(palette, teachers.length, filtered.length),
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
                          _buildSummaryCard(palette, teachers),
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
                            _buildTeacherTable(palette, filtered),
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

  Widget _buildSummaryCard(
    AppThemePalette palette,
    List<TeacherProfileModel> teachers,
  ) {
    final activeCount = teachers
        .where((item) => item.status.toLowerCase() == 'active')
        .length;
    final linkedCount = teachers.where((item) => item.isLinked).length;
    final classTeacherCount = teachers
        .where((item) => item.isClassTeacher)
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
            'Teacher Access Flow',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Principal yahan teacher ka complete record save kare ga aur system isi screen se unique user ID aur strong password generate kare ga.',
            style: TextStyle(color: palette.subtext, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(palette, 'Total', '${teachers.length}'),
              _infoChip(palette, 'Active', '$activeCount'),
              _infoChip(palette, 'Linked', '$linkedCount', highlight: true),
              _infoChip(palette, 'Class Teachers', '$classTeacherCount'),
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
            'Latest Generated Teacher Login',
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
                        ? 'Create Teacher Record'
                        : 'Edit Teacher Record',
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
            _field(_nameController, 'Teacher Name', validator: _required),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _emailController,
                    'Teacher Email',
                    enabled: !isLinkedEditing,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (!value.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _phoneController,
                    'Phone',
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _employeeIdController,
                    'Employee ID',
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_departmentController, 'Department / Program'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    'Class',
                    _selectedClass,
                    _classes,
                    (v) => setState(() => _selectedClass = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    'Section',
                    _selectedSection,
                    _sections,
                    (v) => setState(() => _selectedSection = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _subjectController,
                    'Subject',
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    'Status',
                    _selectedStatus,
                    _statuses,
                    (v) => setState(() => _selectedStatus = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Class Teacher'),
              subtitle: const Text(
                'On karne se teacher class teacher mark ho jayega.',
              ),
              value: _isClassTeacher,
              onChanged: (value) => setState(() => _isClassTeacher = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingTeacher ? null : _saveTeacher,
                icon: _isSavingTeacher
                    ? const LoadingDots(color: Colors.white, size: 7)
                    : Icon(
                        isLinkedEditing
                            ? Icons.save_outlined
                            : Icons.admin_panel_settings_outlined,
                      ),
                label: Text(
                  _isSavingTeacher
                      ? 'Saving...'
                      : isLinkedEditing
                      ? 'Update Teacher Record'
                      : 'Save Teacher + Generate Login',
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
                hintText: 'Search by name, employee ID, subject, email...',
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
              _dropdown(
                'Class',
                _filterClass,
                const ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
                (v) => setState(() => _filterClass = v!),
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Section',
                _filterSection,
                const ['All', 'A', 'B', 'C'],
                (v) => setState(() => _filterSection = v!),
              ),
              const SizedBox(height: 12),
              _dropdown(
                'Status',
                _filterStatus,
                const ['All', 'active', 'inactive'],
                (v) => setState(() => _filterStatus = v!),
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
                _filterStatus = 'All';
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

  Widget _buildTeacherTable(
    AppThemePalette palette,
    List<TeacherProfileModel> teachers,
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
                    'Emp ID',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Subject',
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
          ...teachers.asMap().entries.map((entry) {
            final index = entry.key;
            final profile = entry.value;
            return _buildTeacherRow(palette, index + 1, profile);
          }),
        ],
      ),
    );
  }

  Widget _buildTeacherRow(
    AppThemePalette palette,
    int serialNo,
    TeacherProfileModel profile,
  ) {
    return InkWell(
      onTap: () => _showTeacherDetails(profile),
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
                  if (profile.isClassTeacher)
                    Container(
                      margin: const EdgeInsets.only(left: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'CT',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
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
                profile.employeeId,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                profile.subject,
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
                      onPressed: _isSavingTeacher
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
                    onPressed: () => _editTeacher(profile),
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

  void _showTeacherDetails(TeacherProfileModel profile) {
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
              _detailRow('Employee ID', profile.employeeId),
              _detailRow('Email', profile.teacherEmail),
              _detailRow('Phone', profile.phone),
              _detailRow('Subject', profile.subject),
              _detailRow('Class', '${profile.className}-${profile.section}'),
              if (profile.department.isNotEmpty)
                _detailRow('Department', profile.department),
              _detailRow('Class Teacher', profile.isClassTeacher ? 'Yes' : 'No'),
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
              _editTeacher(profile);
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

  Widget _buildFilterCard(AppThemePalette palette, int total, int showing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Search Teachers',
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                'Total: $total | Showing: $showing',
                style: TextStyle(color: palette.subtext, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  'Class',
                  _filterClass,
                  const [
                    'All',
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
                  ],
                  (v) => setState(() => _filterClass = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  'Section',
                  _filterSection,
                  const ['All', 'A', 'B', 'C'],
                  (v) => setState(() => _filterSection = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  'Status',
                  _filterStatus,
                  const ['All', 'active', 'inactive'],
                  (v) => setState(() => _filterStatus = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name, employee ID, subject, email...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
        'No teacher records found for the selected filters.',
        style: TextStyle(color: palette.subtext),
      ),
    );
  }

  Widget _buildTeacherCard(
    AppThemePalette palette,
    TeacherProfileModel profile,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.fullName,
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (profile.isLinked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Linked',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (profile.isClassTeacher)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Class Teacher',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _compactChip(palette, 'Emp: ${profile.employeeId}'),
                    _compactChip(
                      palette,
                      'Class: ${profile.className}-${profile.section}',
                    ),
                    _compactChip(palette, 'Subject: ${profile.subject}'),
                    if (profile.generatedUserId.isNotEmpty)
                      _compactChip(
                        palette,
                        'ID: ${profile.generatedUserId}',
                        highlight: true,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.teacherEmail}${profile.phone.isNotEmpty ? " • ${profile.phone}" : ""}',
                  style: TextStyle(
                    color: palette.subtext,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!profile.isLinked)
                IconButton(
                  onPressed: _isSavingTeacher
                      ? null
                      : () => _generateCredentialsForProfile(profile),
                  icon: Icon(
                    Icons.vpn_key_outlined,
                    color: palette.primary,
                    size: 20,
                  ),
                  tooltip: 'Generate login',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              IconButton(
                onPressed: () => _editTeacher(profile),
                icon: Icon(
                  Icons.edit_outlined,
                  color: palette.primary,
                  size: 20,
                ),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactChip(
    AppThemePalette palette,
    String text, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlight ? palette.softCard : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: palette.text,
          fontSize: 11,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Widget _field(
    TextEditingController controller,
    String label, {
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

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
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
}
