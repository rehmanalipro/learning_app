import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/animated_page_wrapper.dart';
import '../../../shared/widgets/adaptive_layout.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/result_model.dart';
import '../providers/result_provider.dart';

class StudentResultScreen extends StatefulWidget {
  const StudentResultScreen({super.key});

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen> {
  final ResultProvider _provider = Get.find<ResultProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final RxString _studentId = ''.obs;

  @override
  void initState() {
    super.initState();
    _resolveStudentIdentity();
  }

  Future<void> _resolveStudentIdentity() async {
    _provider.isLoading.value = true;
    final argStudentId = Get.arguments as String?;
    if (argStudentId != null && argStudentId.isNotEmpty) {
      _studentId.value = argStudentId;
      await _loadData();
      return;
    }

    final userData = await _authProvider.loadCurrentUserData();
    final linkedProfileId =
        (userData?['linkedStudentProfileId'] as String? ?? '').trim();
    final fallback = _authProvider.currentUser.value?.uid ?? '';
    _studentId.value = linkedProfileId.isNotEmpty ? linkedProfileId : fallback;
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_studentId.value.isEmpty) {
      _provider.results.clear();
      _provider.isLoading.value = false;
      return;
    }
    _provider.isLoading.value = true;
    await _provider.loadByStudentId(_studentId.value);
    _provider.isLoading.value = false;
  }

  String _calculateGrade(double score, double maxScore) {
    final percent = maxScore == 0 ? 0 : (score / maxScore * 100);
    if (percent >= 90) return 'A+';
    if (percent >= 80) return 'A';
    if (percent >= 70) return 'B+';
    if (percent >= 60) return 'B';
    return 'C';
  }

  String _overallGrade(double score, double maxScore) {
    final percent = maxScore == 0 ? 0 : (score / maxScore) * 100;
    if (percent >= 90) return 'A+';
    if (percent >= 80) return 'A';
    if (percent >= 70) return 'B';
    if (percent >= 60) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final compact = context.isCompactViewport;
    final headingFontSize = context.adaptiveValue<double>(
      compact: 12,
      medium: 12,
      expanded: 12.5,
      wide: 13,
    );
    final dataFontSize = context.adaptiveValue<double>(
      compact: 12,
      medium: 12,
      expanded: 13,
      wide: 13,
    );
    final minTableWidth = context.adaptiveValue<double>(
      compact: 720,
      medium: 780,
      expanded: 860,
      wide: 900,
    );
    final studentProfile = _profileProvider.profileFor('Student');
    final displayStudentName = studentProfile.name.trim().isEmpty
        ? 'Student User'
        : studentProfile.name.trim();
    final programName = (studentProfile.programName ?? '').trim().isEmpty
        ? 'Program not added'
        : studentProfile.programName!.trim();

    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: AppScreenHeader(
        title: 'Student Result',
        subtitle: displayStudentName,
        tertiary: 'Detailed Marks Sheet • $programName',
      ),
      body: AnimatedPageWrapper(
        child: AppRefreshScope(
          onRefresh: _loadData,
          child: Obx(() {
            if (_provider.isLoading.value && _studentId.value.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final results = _provider.results.toList(growable: false);
            final student = results.isNotEmpty
                ? results.first
                : ResultModel(
                    id: 'na',
                    studentId: _studentId.value,
                    studentUid: _authProvider.currentUser.value?.uid ?? '',
                    studentName: displayStudentName,
                    studentEmail: _authProvider.currentUser.value?.email ?? '',
                    admissionNo: studentProfile.admissionNo ?? '',
                    rollNumber: '',
                    className: studentProfile.className ?? '',
                    section: studentProfile.section ?? '',
                    courseCode: '',
                    subject: '',
                    creditHours: 0,
                    score: 0,
                    maxScore: 0,
                    term: '',
                    examType: '',
                    teacherId: '',
                    teacherName: '',
                    remarks: '',
                  );

            double totalObtained = 0;
            double totalMarks = 0;
            final rows = results
                .map((item) {
                  totalObtained += item.score;
                  totalMarks += item.maxScore;
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(item.rollNumber.isEmpty ? '-' : item.rollNumber),
                      ),
                      DataCell(Text(item.subject)),
                      DataCell(Text(item.term)),
                      DataCell(Text(item.examType)),
                      DataCell(Text(item.score.toStringAsFixed(0))),
                      DataCell(Text(item.maxScore.toStringAsFixed(0))),
                      DataCell(
                        Text(_calculateGrade(item.score, item.maxScore)),
                      ),
                    ],
                  );
                })
                .toList(growable: false);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ResponsiveContent(
                maxWidth: 1080,
                padding: context.adaptivePagePadding(
                  compact: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                  medium: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                  expanded: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                ),
                child: Column(
                  children: [
                    _buildStudentInfoCard(
                      palette,
                      compact: compact,
                      infoItems: [
                        MapEntry('Profile ID', student.studentId),
                        MapEntry(
                          'Admission No',
                          student.admissionNo.isEmpty
                              ? (studentProfile.admissionNo ?? '-')
                              : student.admissionNo,
                        ),
                        MapEntry(
                          'Roll No',
                          student.rollNumber.isEmpty ? '-' : student.rollNumber,
                        ),
                        MapEntry(
                          'Class',
                          student.className.isEmpty
                              ? (studentProfile.className ?? '-')
                              : student.className,
                        ),
                        MapEntry(
                          'Section',
                          student.section.isEmpty
                              ? (studentProfile.section ?? '-')
                              : student.section,
                        ),
                        MapEntry('Name', displayStudentName),
                        MapEntry('Program', programName),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      child: results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Abhi aap ka result upload nahi hua.',
                                style: TextStyle(color: palette.subtext),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth > minTableWidth
                                            ? constraints.maxWidth
                                            : minTableWidth,
                                      ),
                                      child: DataTable(
                                        dataRowMinHeight: compact ? 42 : 44,
                                        dataRowMaxHeight: compact ? 50 : 52,
                                        headingRowHeight: compact ? 42 : 44,
                                        columnSpacing: compact ? 18 : 22,
                                        horizontalMargin: compact ? 12 : 14,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              palette.primary,
                                            ),
                                        headingTextStyle: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: headingFontSize,
                                        ),
                                        dataTextStyle: TextStyle(
                                          color: palette.text,
                                          fontSize: dataFontSize,
                                        ),
                                        columns: const [
                                          DataColumn(label: Text('Roll No')),
                                          DataColumn(label: Text('Subject')),
                                          DataColumn(label: Text('Term')),
                                          DataColumn(label: Text('Exam')),
                                          DataColumn(label: Text('Obtained')),
                                          DataColumn(label: Text('Total')),
                                          DataColumn(label: Text('Grade')),
                                        ],
                                        rows: rows,
                                      ),
                                    ),
                                  ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    _buildSummaryCard(
                      palette,
                      compact: compact,
                      totalObtained: totalObtained,
                      totalMarks: totalMarks,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard(
    AppThemePalette palette, {
    required bool compact,
    required List<MapEntry<String, String>> infoItems,
  }) {
    return Card(
      elevation: 1,
      color: palette.surface,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 10),
        child: compact
            ? Column(
                children: infoItems
                    .map(
                      (item) => _compactInfoTile(
                        palette,
                        label: item.key,
                        value: item.value,
                      ),
                    )
                    .toList(growable: false),
              )
            : Table(
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FlexColumnWidth(),
                },
                border: TableBorder.all(color: palette.border),
                children: infoItems
                    .map((item) => _infoRow(item.key, item.value))
                    .toList(growable: false),
              ),
      ),
    );
  }

  Widget _compactInfoTile(
    AppThemePalette palette, {
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.subtext,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    AppThemePalette palette, {
    required bool compact,
    required double totalObtained,
    required double totalMarks,
  }) {
    final cards = [
      _summaryTile(
        palette,
        label: 'Obtained',
        value: totalObtained.toStringAsFixed(0),
      ),
      _summaryTile(
        palette,
        label: 'Total Marks',
        value: totalMarks.toStringAsFixed(0),
      ),
      _summaryTile(
        palette,
        label: 'Overall Grade',
        value: _overallGrade(totalObtained, totalMarks),
        highlight: true,
      ),
    ];

    return Card(
      color: palette.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: compact
            ? Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              )
            : Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _summaryTile(
    AppThemePalette palette, {
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? palette.softCard : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? palette.primary : palette.subtext,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlight ? palette.primary : palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _infoRow(String label, String value) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
