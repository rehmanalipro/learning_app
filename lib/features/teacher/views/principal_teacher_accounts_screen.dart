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

  final List<String> _classes = const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
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
  String _principalName = 'Principal';
  String? _editingProfileId;
  Map<String, String>? _lastIssuedCredentials;
  bool _isSavingTeacher = false;

  TeacherProfileModel? get _editingProfile => _editingProfileId == null
      ? null
      : _provider.teacherProfiles.firstWhereOrNull((item) => item.id == _editingProfileId);

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
        Get.snackbar(
          'Saved',
          'Teacher record saved and login generated successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _resetForm();
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

  Future<void> _generateCredentialsForProfile(TeacherProfileModel profile) async {
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
    Get.snackbar('Copied', '$label copied successfully.', snackPosition: SnackPosition.BOTTOM);
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
    return items.where((profile) {
      final matchesClass = _filterClass == 'All' || profile.className == _filterClass;
      final matchesSection = _filterSection == 'All' || profile.section == _filterSection;
      final matchesStatus = _filterStatus == 'All' || profile.status == _filterStatus;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          profile.fullName.toLowerCase().contains(query) ||
          profile.teacherEmail.toLowerCase().contains(query) ||
          profile.employeeId.toLowerCase().contains(query) ||
          profile.subject.toLowerCase().contains(query) ||
          profile.generatedUserId.toLowerCase().contains(query);
      return matchesClass && matchesSection && matchesStatus && matchesSearch;
    }).toList(growable: false);
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
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
              maxWidth: 1100,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(palette, teachers),
                  if (_lastIssuedCredentials != null) ...[
                    const SizedBox(height: 16),
                    _buildLatestCredentialsCard(palette),
                  ],
                  const SizedBox(height: 16),
                  _buildFormCard(palette),
                  const SizedBox(height: 16),
                  _buildFilterCard(palette, teachers.length, filtered.length),
                  const SizedBox(height: 16),
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
                    ...filtered.map((profile) => _buildTeacherCard(palette, profile)),
                ],
              ),
            ),
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
          onPressed: value.trim().isEmpty ? null : () => _copyText(label, value),
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
    final activeCount =
        teachers.where((item) => item.status.toLowerCase() == 'active').length;
    final linkedCount = teachers.where((item) => item.isLinked).length;
    final classTeacherCount = teachers.where((item) => item.isClassTeacher).length;
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
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 16),
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
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            creds['fullName'] ?? '',
            style: TextStyle(color: palette.subtext, fontWeight: FontWeight.w600),
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
                    _editingProfileId == null ? 'Create Teacher Record' : 'Edit Teacher Record',
                    style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                if (_editingProfileId != null)
                  TextButton(onPressed: _resetForm, child: const Text('Cancel Edit')),
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
                      if (value == null || value.trim().isEmpty) return 'Required';
                      if (!value.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _field(_phoneController, 'Phone', keyboardType: TextInputType.phone)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_employeeIdController, 'Employee ID', validator: _required)),
                const SizedBox(width: 12),
                Expanded(child: _field(_departmentController, 'Department / Program')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dropdown('Class', _selectedClass, _classes, (v) => setState(() => _selectedClass = v!))),
                const SizedBox(width: 12),
                Expanded(child: _dropdown('Section', _selectedSection, _sections, (v) => setState(() => _selectedSection = v!))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_subjectController, 'Subject', validator: _required)),
                const SizedBox(width: 12),
                Expanded(child: _dropdown('Status', _selectedStatus, _statuses, (v) => setState(() => _selectedStatus = v!))),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Class Teacher'),
              subtitle: const Text('On karne se teacher class teacher mark ho jayega.'),
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

  Widget _buildFilterCard(AppThemePalette palette, int total, int showing) {
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
            'Search Teachers',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Total: $total | Showing: $showing', style: TextStyle(color: palette.subtext)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropdown('Class Filter', _filterClass, const ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'], (v) => setState(() => _filterClass = v!)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown('Section Filter', _filterSection, const ['All', 'A', 'B', 'C'], (v) => setState(() => _filterSection = v!)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _dropdown('Status Filter', _filterStatus, const ['All', 'active', 'inactive'], (v) => setState(() => _filterStatus = v!)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name, email, user ID, employee ID, or subject',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      child: Text('No teacher records found for the selected filters.', style: TextStyle(color: palette.subtext)),
    );
  }

  Widget _buildTeacherCard(AppThemePalette palette, TeacherProfileModel profile) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(palette, 'Employee', profile.employeeId),
                    _infoChip(palette, 'Class', '${profile.className}-${profile.section}'),
                    _infoChip(palette, 'Subject', profile.subject),
                    if (profile.department.isNotEmpty) _infoChip(palette, 'Dept', profile.department),
                    if (profile.isClassTeacher) _infoChip(palette, 'Role', 'Class Teacher', highlight: true),
                    if (profile.generatedUserId.isNotEmpty) _infoChip(palette, 'User ID', profile.generatedUserId, highlight: true),
                    _infoChip(
                      palette,
                      profile.isLinked ? 'Account Ready' : 'Login Pending',
                      profile.isLinked ? (profile.linkedUserEmail.isEmpty ? 'Account connected' : profile.linkedUserEmail) : 'Generate login from this record',
                      highlight: profile.isLinked,
                      warning: !profile.isLinked,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (profile.teacherEmail.isNotEmpty) Text('Email: ${profile.teacherEmail}', style: TextStyle(color: palette.subtext)),
                if (profile.phone.isNotEmpty) Text('Phone: ${profile.phone}', style: TextStyle(color: palette.subtext)),
                Text('Status: ${profile.status}', style: TextStyle(color: palette.subtext)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              if (!profile.isLinked)
                IconButton(
                  onPressed: _isSavingTeacher
                      ? null
                      : () => _generateCredentialsForProfile(profile),
                  icon: Icon(Icons.vpn_key_outlined, color: palette.primary),
                  tooltip: 'Generate teacher login',
                ),
              IconButton(
                onPressed: () => _editTeacher(profile),
                icon: Icon(Icons.edit_outlined, color: palette.primary),
                tooltip: 'Edit teacher record',
              ),
              if (profile.generatedUserId.isNotEmpty)
                IconButton(
                  onPressed: () => _copyText('User ID', profile.generatedUserId),
                  icon: Icon(Icons.copy_outlined, color: palette.primary),
                  tooltip: 'Copy user ID',
                ),
            ],
          ),
        ],
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
          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
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
        style: TextStyle(color: foregroundColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
