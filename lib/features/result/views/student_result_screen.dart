import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/animated_page_wrapper.dart';
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
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                child: Column(
                  children: [
                    Card(
                      elevation: 1,
                      color: palette.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Table(
                          columnWidths: const {
                            0: FixedColumnWidth(100),
                            1: FlexColumnWidth(),
                          },
                          border: TableBorder.all(color: Colors.black12),
                          children: [
                            _infoRow('Profile ID', student.studentId),
                            _infoRow(
                              'Admission No',
                              student.admissionNo.isEmpty
                                  ? (studentProfile.admissionNo ?? '-')
                                  : student.admissionNo,
                            ),
                            _infoRow(
                              'Roll No',
                              student.rollNumber.isEmpty
                                  ? '-'
                                  : student.rollNumber,
                            ),
                            _infoRow(
                              'Class',
                              student.className.isEmpty
                                  ? (studentProfile.className ?? '-')
                                  : student.className,
                            ),
                            _infoRow(
                              'Section',
                              student.section.isEmpty
                                  ? (studentProfile.section ?? '-')
                                  : student.section,
                            ),
                            _infoRow('Name', displayStudentName),
                            _infoRow('Program', programName),
                          ],
                        ),
                      ),
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
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        dataRowMinHeight: 30,
                                        dataRowMaxHeight: 36,
                                        headingRowHeight: 34,
                                        columnSpacing: 10,
                                        horizontalMargin: 8,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              palette.primary,
                                            ),
                                        headingTextStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                        dataTextStyle: TextStyle(
                                          color: palette.text,
                                          fontSize: 10,
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
                    Card(
                      color: palette.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Obtained Marks: ${totalObtained.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Marks: ${totalMarks.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Overall Grade: ${_overallGrade(totalObtained, totalMarks)}',
                              style: TextStyle(
                                color: palette.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  TableRow _infoRow(String label, String value) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          child: Text(value, style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
