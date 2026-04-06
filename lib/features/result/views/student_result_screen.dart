import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../models/result_model.dart';
import '../providers/result_provider.dart';

class StudentResultScreen extends StatefulWidget {
  const StudentResultScreen({super.key});

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen>
    with SingleTickerProviderStateMixin {
  final ResultProvider _provider = Get.put(ResultProvider());
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final RxString _studentId = 's-001'.obs;

  late final TabController _tabController;
  final classTabs = List<String>.generate(10, (index) => 'Class ${index + 1}');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: classTabs.length, vsync: this);

    final argStudentId = Get.arguments as String?;
    if (argStudentId != null && argStudentId.isNotEmpty) {
      _studentId.value = argStudentId;
    }

    _loadData();
    ever(_studentId, (_) => _loadData());
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _provider.isLoading.value = true;
    await _provider.loadClassResults(className: _selectedClassValue());
    _provider.isLoading.value = false;
  }

  String _selectedClassValue() {
    return (_tabController.index + 1).toString();
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
    final selectedClassLabel = 'Class ${_selectedClassValue()}';
    final palette = context.appPalette;
    final studentProfile = _profileProvider.profileFor('Student');
    final principalProfile = _profileProvider.profileFor('Principal');
    final universityName = principalProfile.name.trim().isEmpty
        ? 'Principal User'
        : principalProfile.name.trim();
    final displayStudentName = studentProfile.name.trim().isEmpty
        ? 'Student User'
        : studentProfile.name.trim();
    final programName = (studentProfile.programName ?? '').trim().isEmpty
        ? 'Program not added'
        : studentProfile.programName!.trim();

    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: AppScreenHeader(
        title: universityName,
        subtitle: displayStudentName,
        tertiary: 'Detailed Marks Sheet • $programName',
      ),
      body: ResponsiveContent(
        maxWidth: 1080,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        child: Column(
          children: [
            Obx(() {
              final layout = _provider.results.toList(growable: false);
              final student = layout.isNotEmpty
                  ? layout.first
                  : ResultModel(
                      id: 'na',
                      studentId: _studentId.value,
                      studentName: displayStudentName,
                      className: _selectedClassValue(),
                      section: 'A',
                      courseCode: '',
                      subject: '',
                      creditHours: 0,
                      score: 0,
                      maxScore: 0,
                      term: '',
                      examType: '',
                      teacherId: '',
                      teacherName: '',
                    );

              return Card(
                elevation: 1,
                color: palette.surface,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(88),
                      1: FlexColumnWidth(),
                    },
                    border: TableBorder.all(color: Colors.black12),
                    children: [
                      _infoRow('Reg. No', student.studentId),
                      _infoRow('Session', '2025-2026'),
                      _infoRow('Class', selectedClassLabel),
                      _infoRow('Name', displayStudentName),
                      _infoRow('Program', programName),
                    ],
                  ),
                ),
              );
            }),
            Expanded(
              child: Obx(() {
              final layout = _provider.results.toList(growable: false);
              double totalObtained = 0;
              double totalMarks = 0;
              final rows = layout.map((item) {
                final grade = _calculateGrade(item.score, item.maxScore);
                totalObtained += item.score;
                totalMarks += item.maxScore;
                return DataRow(
                  cells: [
                    DataCell(Text(item.courseCode)),
                    DataCell(Text(item.subject)),
                    DataCell(Text(item.score.toStringAsFixed(0))),
                    DataCell(Text(item.maxScore.toStringAsFixed(0))),
                    DataCell(Text(grade)),
                  ],
                );
              }).toList();

              return AppRefreshScope(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Card(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: palette.primary,
                        labelColor: palette.primary,
                        unselectedLabelColor: palette.subtext,
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(fontSize: 11),
                        tabs: classTabs.map((e) => Tab(text: e)).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: layout.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '$selectedClassLabel ke liye abhi koi result nahi hai.',
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
                                    dataRowMinHeight: 28,
                                    dataRowMaxHeight: 34,
                                    headingRowHeight: 32,
                                    columnSpacing: 10,
                                    horizontalMargin: 8,
                                    headingRowColor: WidgetStateProperty.all(
                                      palette.primary,
                                    ),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    dataTextStyle: TextStyle(
                                      color: palette.text,
                                      fontSize: 9.5,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Code')),
                                      DataColumn(label: Text('Course')),
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
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Obtained Marks: ${totalObtained.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Marks: ${totalMarks.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Grade: ${_overallGrade(totalObtained, totalMarks)}',
                              style: TextStyle(
                                color: palette.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
                ),
              );
              }),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _infoRow(String label, String value) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          child: Text(value, style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
