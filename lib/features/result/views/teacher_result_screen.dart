import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/services/class_roster_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../models/result_model.dart';
import '../providers/result_provider.dart';

class TeacherResultScreen extends StatefulWidget {
  final String roleLabel;

  const TeacherResultScreen({super.key, this.roleLabel = 'Teacher'});

  @override
  State<TeacherResultScreen> createState() => _TeacherResultScreenState();
}

class _TeacherResultScreenState extends State<TeacherResultScreen> {
  final ResultProvider _provider = Get.find<ResultProvider>();
  final ClassBindingService _classBinding = Get.find<ClassBindingService>();
  final ClassRosterService _rosterService = Get.find<ClassRosterService>();
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();

  static const _terms = ['Mid', 'Final', 'Annual'];
  static const _examTypes = ['Written', 'Practical', 'Oral'];
  static const _classes = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  static const _sections = ['A', 'B', 'C'];

  String _selectedTerm = 'Mid';
  String _selectedExamType = 'Written';
  String _selectedClass = '1';
  String _selectedSection = 'A';
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // student profile id -> score controllers
  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, TextEditingController> _maxScoreControllers = {};
  final TextEditingController _commonMaxController = TextEditingController(
    text: '100',
  );

  final RxBool _isSubmitting = false.obs;
  String _teacherName = 'Teacher';
  String _teacherId = '';
  String _searchQuery = '';

  bool get _isPrincipal => widget.roleLabel.toLowerCase() == 'principal';
  String get _activeClass =>
      _isPrincipal ? _selectedClass : _classBinding.className.value;
  String get _activeSection =>
      _isPrincipal ? _selectedSection : _classBinding.section.value;
  String get _activeSubject => _isPrincipal
      ? _subjectController.text.trim()
      : _classBinding.subject.value;

  String _studentKey(Map<String, dynamic> student) {
    return student['studentProfileId'] as String? ??
        student['uid'] as String? ??
        '';
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherIdentity();
    if (_isPrincipal) {
      _selectedClass = _classes.first;
      _selectedSection = _sections.first;
    }
    _loadRosterAndResults();
  }

  Future<void> _loadTeacherIdentity() async {
    final userData = await _authProvider.loadCurrentUserData();
    if (!mounted) return;
    setState(() {
      _teacherId = _authProvider.currentUser.value?.uid ?? '';
      _teacherName = ((userData?['name'] as String?) ?? '').trim().isEmpty
          ? 'Teacher'
          : (userData?['name'] as String).trim();
    });
  }

  Future<void> _loadRosterAndResults() async {
    final className = _activeClass;
    final section = _activeSection;
    if (className.isEmpty || section.isEmpty) return;
    await _rosterService.loadRoster(className: className, section: section);
    _initControllers();
    await _loadExistingResults();
  }

  void _initControllers() {
    for (final student in _rosterService.roster) {
      final studentKey = _studentKey(student);
      if (studentKey.isEmpty) continue;
      _scoreControllers.putIfAbsent(studentKey, () => TextEditingController());
      _maxScoreControllers.putIfAbsent(
        studentKey,
        () => TextEditingController(text: '100'),
      );
    }
  }

  Future<void> _loadExistingResults() async {
    final className = _activeClass;
    final section = _activeSection;
    final subject = _activeSubject;
    if (className.isEmpty || section.isEmpty || subject.isEmpty) return;

    await _provider.loadClassTermExam(
      className: className,
      section: section,
      term: _selectedTerm,
      examType: _selectedExamType,
    );

    final existingForSubject = _provider.results
        .where((item) => item.subject == subject)
        .toList(growable: false);

    for (final student in _rosterService.roster) {
      final studentKey = _studentKey(student);
      if (studentKey.isEmpty) continue;
      final existing = existingForSubject.firstWhereOrNull(
        (item) => item.studentId == studentKey,
      );
      _scoreControllers[studentKey]?.text = existing == null
          ? ''
          : _formatNumber(existing.score);
      _maxScoreControllers[studentKey]?.text = existing == null
          ? _commonMaxController.text
          : _formatNumber(existing.maxScore);
    }
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  void _applyCommonMaxScore() {
    final maxValue = _commonMaxController.text.trim();
    if (maxValue.isEmpty) return;
    for (final controller in _maxScoreControllers.values) {
      controller.text = maxValue;
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    for (final c in _maxScoreControllers.values) {
      c.dispose();
    }
    _commonMaxController.dispose();
    _subjectController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitResults() async {
    final roster = _rosterService.roster.toList();
    if (roster.isEmpty) {
      Get.snackbar('No students', 'Roster is empty.');
      return;
    }

    final scores = <String, ({double score, double maxScore})>{};
    for (final student in roster) {
      final studentKey = _studentKey(student);
      if (studentKey.isEmpty) continue;
      final score = double.tryParse(
        _scoreControllers[studentKey]?.text.trim() ?? '',
      );
      final maxScore = double.tryParse(
        _maxScoreControllers[studentKey]?.text.trim() ?? '',
      );
      if (score == null || maxScore == null || maxScore <= 0) {
        Get.snackbar(
          'Validation',
          'Please enter valid score and max score for all students.',
        );
        return;
      }
      scores[studentKey] = (score: score, maxScore: maxScore);
    }

    _isSubmitting.value = true;
    try {
      await _provider.bulkUpsertResults(
        roster: roster,
        className: _activeClass,
        section: _activeSection,
        subject: _activeSubject,
        term: _selectedTerm,
        examType: _selectedExamType,
        teacherId: _teacherId,
        teacherName: _teacherName,
        scores: scores,
      );
      await _loadExistingResults();
      Get.snackbar('Saved', 'Whole class result updated successfully.');
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<void> _saveSingleResult(Map<String, dynamic> student) async {
    final studentKey = _studentKey(student);
    if (studentKey.isEmpty) return;

    final subject = _activeSubject;
    if (subject.isEmpty) {
      Get.snackbar('Missing subject', 'Please enter a subject first.');
      return;
    }

    final score = double.tryParse(
      _scoreControllers[studentKey]?.text.trim() ?? '',
    );
    final maxScore = double.tryParse(
      _maxScoreControllers[studentKey]?.text.trim() ?? '',
    );
    if (score == null || maxScore == null || maxScore <= 0) {
      Get.snackbar(
        'Validation',
        'Please enter valid score and max score for this student.',
      );
      return;
    }

    final result = ResultModel(
      id: _provider.buildResultId(
        studentKey: studentKey,
        subject: subject,
        term: _selectedTerm,
        examType: _selectedExamType,
      ),
      studentId: studentKey,
      studentUid: student['linkedUserUid'] as String? ?? '',
      studentName: student['name'] as String? ?? '',
      studentEmail: student['email'] as String? ?? '',
      admissionNo: student['admissionNo'] as String? ?? '',
      rollNumber: student['rollNumber'] as String? ?? '',
      className: _activeClass,
      section: _activeSection,
      courseCode: '',
      subject: subject,
      creditHours: 1,
      score: score,
      maxScore: maxScore,
      term: _selectedTerm,
      examType: _selectedExamType,
      teacherId: _teacherId,
      teacherName: _teacherName,
      remarks: '',
    );

    await _provider.upsertResult(result);
    await _loadExistingResults();
    Get.snackbar('Saved', 'Result updated for ${result.studentName}.');
  }

  Future<void> _deleteSingleResult(Map<String, dynamic> student) async {
    final studentKey = _studentKey(student);
    if (studentKey.isEmpty || _activeSubject.isEmpty) return;

    final resultId = _provider.buildResultId(
      studentKey: studentKey,
      subject: _activeSubject,
      term: _selectedTerm,
      examType: _selectedExamType,
    );

    final existing = _provider.results.firstWhereOrNull(
      (item) => item.id == resultId,
    );
    if (existing == null) {
      Get.snackbar('Not found', 'No saved result found for this student.');
      return;
    }

    await _provider.deleteResult(resultId);
    _scoreControllers[studentKey]?.clear();
    _maxScoreControllers[studentKey]?.text = _commonMaxController.text;
    setState(() {});
    Get.snackbar('Deleted', 'Result removed for ${existing.studentName}.');
  }

  List<Map<String, dynamic>> _filteredRoster(
    List<Map<String, dynamic>> roster,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return roster;

    return roster
        .where((student) {
          final name = (student['name'] as String? ?? '').toLowerCase();
          final studentKey = _studentKey(student).toLowerCase();
          final userId = (student['userId'] as String? ?? '').toLowerCase();
          final admissionNo = (student['admissionNo'] as String? ?? '')
              .toLowerCase();
          final rollNumber = (student['rollNumber'] as String? ?? '')
              .toLowerCase();
          final email = (student['email'] as String? ?? '').toLowerCase();
          return name.contains(query) ||
              studentKey.contains(query) ||
              userId.contains(query) ||
              admissionNo.contains(query) ||
              rollNumber.contains(query) ||
              email.contains(query);
        })
        .toList(growable: false);
  }

  int get _studentsMissingRollNumber => _rosterService.roster.where((student) {
    final rollNumber = (student['rollNumber'] as String? ?? '').trim();
    return rollNumber.isEmpty;
  }).length;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: AppScreenHeader(
        title: _isPrincipal ? 'Principal Result Entry' : 'Result Entry',
        subtitle: _isPrincipal
            ? 'Upload or update marks for any class'
            : 'Enter marks for your class',
      ),
      body: AppRefreshScope(
        onRefresh: _loadRosterAndResults,
        child: Obx(() {
          final isRosterLoading = _rosterService.isLoading.value;
          final roster = _rosterService.roster.toList();
          final visibleRoster = _filteredRoster(roster);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
              maxWidth: 900,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Read-only class info
                  _buildClassInfoCard(palette),
                  const SizedBox(height: 16),
                  // Term & examType dropdowns
                  _buildDropdownRow(palette),
                  const SizedBox(height: 16),
                  _buildBulkActionsCard(palette),
                  const SizedBox(height: 16),
                  _buildSearchCard(
                    palette,
                    roster.length,
                    visibleRoster.length,
                  ),
                  const SizedBox(height: 12),
                  _buildRosterGuideCard(palette, roster.length),
                  const SizedBox(height: 16),
                  // Roster list
                  if (isRosterLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (roster.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No students enrolled in your class yet.',
                        style: TextStyle(color: palette.subtext),
                      ),
                    )
                  else if (visibleRoster.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No student matched your search.',
                        style: TextStyle(color: palette.subtext),
                      ),
                    )
                  else
                    _buildRosterList(palette, visibleRoster),
                  const SizedBox(height: 20),
                  if (!isRosterLoading && roster.isNotEmpty)
                    _buildSubmitButton(palette),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildClassInfoCard(AppThemePalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          if (_isPrincipal) ...[
            SizedBox(
              width: 150,
              child: _buildDropdown(
                palette: palette,
                label: 'Class',
                initialValue: _selectedClass,
                items: _classes,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _selectedClass = v);
                  await _loadRosterAndResults();
                },
              ),
            ),
            SizedBox(
              width: 150,
              child: _buildDropdown(
                palette: palette,
                label: 'Section',
                initialValue: _selectedSection,
                items: _sections,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _selectedSection = v);
                  await _loadRosterAndResults();
                },
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _subjectController,
                onSubmitted: (_) async => _loadRosterAndResults(),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  filled: true,
                  fillColor: palette.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.border),
                  ),
                ),
              ),
            ),
          ] else ...[
            _readOnlyChip(palette, 'Class', _classBinding.className.value),
            _readOnlyChip(palette, 'Section', _classBinding.section.value),
            _readOnlyChip(palette, 'Subject', _classBinding.subject.value),
          ],
        ],
      ),
    );
  }

  Widget _readOnlyChip(AppThemePalette palette, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: palette.subtext)),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(AppThemePalette palette) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            palette: palette,
            label: 'Term',
            initialValue: _selectedTerm,
            items: _terms,
            onChanged: (v) async {
              setState(() => _selectedTerm = v!);
              await _loadExistingResults();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdown(
            palette: palette,
            label: 'Exam Type',
            initialValue: _selectedExamType,
            items: _examTypes,
            onChanged: (v) async {
              setState(() => _selectedExamType = v!);
              await _loadExistingResults();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionsCard(AppThemePalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Whole Class Result Update',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.roleLabel} $_teacherName ek click se puri class ke marks save ya update kar sakta hai.',
            style: TextStyle(color: palette.subtext, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commonMaxController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Common Max Marks',
                    isDense: true,
                    filled: true,
                    fillColor: palette.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _applyCommonMaxScore,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Apply to All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.inverseText,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tip: search by student name, user ID, admission number, roll number, or email and update only the rows you need.',
            style: TextStyle(color: palette.subtext, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(
    AppThemePalette palette,
    int totalStudents,
    int visibleStudents,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Student',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total: $totalStudents | Showing: $visibleStudents',
            style: TextStyle(color: palette.subtext),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText:
                  'Search by name, user ID, admission no, roll number, or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: palette.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterGuideCard(AppThemePalette palette, int totalStudents) {
    final missingRolls = _studentsMissingRollNumber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _statusChip(
            palette,
            icon: Icons.groups_outlined,
            label: '$totalStudents students loaded automatically',
            highlighted: true,
          ),
          _statusChip(
            palette,
            icon: Icons.search_outlined,
            label: 'Search by user ID, roll no, admission no, name, or email',
          ),
          _statusChip(
            palette,
            icon: missingRolls == 0
                ? Icons.verified_outlined
                : Icons.warning_amber_rounded,
            label: missingRolls == 0
                ? 'All students have roll numbers'
                : '$missingRolls students missing roll numbers',
            warning: missingRolls > 0,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    AppThemePalette palette, {
    required IconData icon,
    required String label,
    bool highlighted = false,
    bool warning = false,
  }) {
    final backgroundColor = warning
        ? const Color(0xFFFFF4E5)
        : highlighted
        ? palette.softCard
        : palette.surfaceAlt;
    final foregroundColor = warning ? const Color(0xFFB96A00) : palette.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required AppThemePalette palette,
    required String label,
    required String initialValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: onChanged,
    );
  }

  Widget _buildRosterList(
    AppThemePalette palette,
    List<Map<String, dynamic>> roster,
  ) {
    return Column(
      children: roster
          .map((student) {
            final studentKey = _studentKey(student);
            final name = student['name'] as String? ?? '';
            final email = student['email'] as String? ?? '';
            final userId = student['userId'] as String? ?? '';
            final admissionNo = student['admissionNo'] as String? ?? '';
            final rollNumber = student['rollNumber'] as String? ?? '';
            final shortKey = studentKey.length <= 10
                ? studentKey
                : '${studentKey.substring(0, 10)}...';
            final resultId = _provider.buildResultId(
              studentKey: studentKey,
              subject: _activeSubject,
              term: _selectedTerm,
              examType: _selectedExamType,
            );
            final existing = _provider.results.firstWhereOrNull(
              (item) => item.id == resultId,
            );

            _scoreControllers.putIfAbsent(
              studentKey,
              () => TextEditingController(),
            );
            _maxScoreControllers.putIfAbsent(
              studentKey,
              () => TextEditingController(text: '100'),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _identityChip(
                              palette,
                              icon: Icons.badge_outlined,
                              label: rollNumber.isEmpty
                                  ? 'Roll No missing'
                                  : 'Roll No: $rollNumber',
                              warning: rollNumber.isEmpty,
                            ),
                            _identityChip(
                              palette,
                              icon: Icons.confirmation_number_outlined,
                              label: admissionNo.isEmpty
                                  ? 'Admission missing'
                                  : 'Admission: $admissionNo',
                              warning: admissionNo.isEmpty,
                            ),
                            _identityChip(
                              palette,
                              icon: Icons.fingerprint_outlined,
                              label: 'Record: $shortKey',
                            ),
                            if (userId.isNotEmpty)
                              _identityChip(
                                palette,
                                icon: Icons.person_pin_circle_outlined,
                                label: 'User ID: $userId',
                              ),
                          ],
                        ),
                        if (email.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              email,
                              style: TextStyle(
                                color: palette.subtext,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (rollNumber.isNotEmpty)
                          Text(
                            'Search works with user ID, roll number, admission number, and linked email.',
                            style: TextStyle(
                              color: palette.subtext,
                              fontSize: 11,
                            ),
                          ),
                        if (existing != null)
                          Text(
                            'Saved for ${existing.term} | ${existing.examType}',
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _scoreControllers[studentKey],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Score',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _maxScoreControllers[studentKey],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Max',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Save student result',
                        onPressed: () => _saveSingleResult(student),
                        style: IconButton.styleFrom(
                          backgroundColor: palette.softCard,
                        ),
                        icon: Icon(Icons.save_outlined, color: palette.primary),
                      ),
                      const SizedBox(height: 6),
                      IconButton(
                        tooltip: 'Delete student result',
                        onPressed: existing == null
                            ? null
                            : () => _deleteSingleResult(student),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF1F1),
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFD64545),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _identityChip(
    AppThemePalette palette, {
    required IconData icon,
    required String label,
    bool warning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF1F1) : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: warning ? const Color(0xFFD64545) : palette.subtext,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: warning ? const Color(0xFFD64545) : palette.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppThemePalette palette) {
    return SizedBox(
      width: double.infinity,
      child: Obx(
        () => ElevatedButton.icon(
          onPressed: _isSubmitting.value ? null : _submitResults,
          icon: _isSubmitting.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            _isSubmitting.value ? 'Updating...' : 'Update Whole Class Result',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: palette.inverseText,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
