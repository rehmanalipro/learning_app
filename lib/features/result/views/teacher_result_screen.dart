import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../models/result_model.dart';
import '../providers/result_provider.dart';

class TeacherResultScreen extends StatefulWidget {
  const TeacherResultScreen({super.key});

  @override
  State<TeacherResultScreen> createState() => _TeacherResultScreenState();
}

class _TeacherResultScreenState extends State<TeacherResultScreen> {
  final ResultProvider _provider = Get.put(ResultProvider());

  final RxString _className = '1'.obs;
  final RxString _section = 'A'.obs;
  final classOptions = List<String>.generate(10, (index) => '${index + 1}');
  final Map<String, List<String>> _classSubjects = const {
    '1': ['English', 'Mathematics'],
    '2': ['English Grammar', 'General Science'],
    '3': ['Urdu', 'Mathematics'],
    '4': ['Science', 'Social Studies'],
    '5': ['Advanced English', 'Computer Basics'],
    '6': ['Biology', 'Chemistry'],
    '7': ['Physics', 'Islamiyat'],
    '8': ['Geography', 'History'],
    '9': ['Algebra', 'Chemistry'],
    '10': ['Physics', 'Biology'],
  };

  final TextEditingController studentIdController = TextEditingController(
    text: 's-001',
  );
  final TextEditingController studentNameController = TextEditingController(
    text: 'Student User',
  );
  final TextEditingController obtainedController = TextEditingController();
  final TextEditingController totalMarksController = TextEditingController(
    text: '100',
  );
  String _selectedSubject = 'English';

  final RxBool isTeacherSubmitting = false.obs;

  @override
  void initState() {
    super.initState();
    _selectedSubject = _subjectsForClass(_className.value).first;
    _loadFiltered();
    ever(_className, (_) {
      setState(() {
        _selectedSubject = _subjectsForClass(_className.value).first;
      });
      _loadFiltered();
    });
  }

  Future<void> _loadFiltered() async {
    await _provider.loadClassResults(
      className: _className.value,
      section: _section.value,
    );
  }

  String _courseCodeFromSubject(String subject) {
    final cleaned = subject.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z]'),
      '',
    );
    final prefix = cleaned.isEmpty
        ? 'SUB'
        : cleaned.substring(0, cleaned.length.clamp(0, 3));
    return '$prefix-${_className.value.padLeft(2, '0')}';
  }

  String _gradeLabel(double score, double maxScore) {
    final percent = maxScore == 0 ? 0 : (score / maxScore) * 100;
    if (percent >= 90) return 'A+';
    if (percent >= 80) return 'A';
    if (percent >= 70) return 'B';
    if (percent >= 60) return 'C';
    return 'D';
  }

  List<String> _subjectsForClass(String className) {
    return _classSubjects[className] ?? const ['General Subject'];
  }

  double _averagePercentage(List<ResultModel> results) {
    if (results.isEmpty) return 0;
    final total = results.fold<double>(
      0,
      (sum, item) =>
          sum + ((item.maxScore == 0) ? 0 : (item.score / item.maxScore) * 100),
    );
    return total / results.length;
  }

  String _bestGrade(List<ResultModel> results) {
    if (results.isEmpty) return '--';
    final order = ['D', 'C', 'B', 'A', 'A+'];
    var bestIndex = 0;
    for (final item in results) {
      final grade = _gradeLabel(item.score, item.maxScore);
      final gradeIndex = order.indexOf(grade);
      if (gradeIndex > bestIndex) {
        bestIndex = gradeIndex;
      }
    }
    return order[bestIndex];
  }

  Future<void> _saveResult() async {
    final sid = studentIdController.text.trim();
    final sname = studentNameController.text.trim();
    final subject = _selectedSubject.trim();
    final score = double.tryParse(obtainedController.text.trim());
    final total = double.tryParse(totalMarksController.text.trim());

    if (sid.isEmpty ||
        sname.isEmpty ||
        subject.isEmpty ||
        score == null ||
        total == null ||
        total <= 0) {
      Get.snackbar(
        'Validation',
        'Class, subject, obtained marks aur total marks sahi enter karein.',
      );
      return;
    }

    isTeacherSubmitting.value = true;
    await _provider.upsertResult(
      ResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: sid,
        studentName: sname,
        className: _className.value,
        section: _section.value,
        courseCode: _courseCodeFromSubject(subject),
        subject: subject,
        creditHours: 1,
        score: score,
        maxScore: total,
        term: 'Annual',
        examType: 'Final',
        teacherId: 't-${_className.value}',
        teacherName: 'Current Teacher',
      ),
    );
    await _loadFiltered();
    isTeacherSubmitting.value = false;

    obtainedController.clear();
    totalMarksController.text = '100';

    Get.snackbar(
      'Saved',
      'Class ${_className.value} ka $subject result update ho gaya.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: AppScreenHeader(
        title: 'Teacher Result Entry',
        subtitle: 'Class wise marks management',
        tertiary: 'Select class, choose subject, then save marks',
      ),
      body: Obx(() {
        final results = _provider.results;
        final averagePercentage = _averagePercentage(results);

        return AppRefreshScope(
          onRefresh: _loadFiltered,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
            maxWidth: 1100,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(palette, results, averagePercentage),
              const SizedBox(height: 16),
              _buildClassSelector(palette),
              const SizedBox(height: 16),
              _buildEntryForm(palette),
              const SizedBox(height: 16),
              _buildResultsTable(palette, results),
            ],
          ),
          ),
          ),
        );
      }),
    );
  }

  Widget _buildHeroCard(
    AppThemePalette palette,
    List<ResultModel> results,
    double averagePercentage,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.primary,
            Color.lerp(palette.primary, palette.accent, 0.72)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class ${_className.value} Result Desk',
            style: TextStyle(
              color: palette.inverseText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Marks update karein, performance review karein, aur result records ko clean dashboard me manage karein.',
            style: TextStyle(
              color: palette.inverseText.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricChip(
                palette: palette,
                label: 'Students',
                value: '${results.length}',
              ),
              _buildMetricChip(
                palette: palette,
                label: 'Average',
                value: '${averagePercentage.toStringAsFixed(0)}%',
              ),
              _buildMetricChip(
                palette: palette,
                label: 'Top Grade',
                value: _bestGrade(results),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector(AppThemePalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _dropdown('Class', classOptions, _className),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.softCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Selected: Class ${_className.value} - Section ${_section.value}',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryForm(AppThemePalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.softCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter student marks',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adaptive form use ho raha hai, is liye small screens par bhi fields neatly stack hongi.',
                      style: TextStyle(
                        color: palette.subtext,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              return Column(
                children: [
                  if (compact) ...[
                    _textField('Student ID', studentIdController),
                    const SizedBox(height: 12),
                    _textField('Student Name', studentNameController),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _textField('Student ID', studentIdController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            'Student Name',
                            studentNameController,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (compact) ...[
                    _subjectField(),
                    const SizedBox(height: 12),
                    _textField(
                      'Obtained Marks',
                      obtainedController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Total Marks',
                      totalMarksController,
                      keyboardType: TextInputType.number,
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(flex: 2, child: _subjectField()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            'Obtained Marks',
                            obtainedController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            'Total Marks',
                            totalMarksController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => ElevatedButton.icon(
                onPressed: isTeacherSubmitting.value ? null : _saveResult,
                icon: Icon(
                  isTeacherSubmitting.value
                      ? Icons.hourglass_top_rounded
                      : Icons.save_outlined,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.inverseText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                label: Text(
                  isTeacherSubmitting.value ? 'Saving...' : 'Save Result',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(
    AppThemePalette palette,
    List<ResultModel> results,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: _provider.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
          ? Column(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 42,
                  color: palette.subtext,
                ),
                const SizedBox(height: 10),
                Text(
                  'Class ${_className.value} ke liye abhi koi result nahi hai.',
                  style: TextStyle(
                    color: palette.subtext,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upar form se pehla record add karke class report banana start karein.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.subtext),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saved results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.softCard,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${results.length} records',
                        style: TextStyle(
                          color: palette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 18,
                    headingRowHeight: 46,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 86,
                    headingRowColor: WidgetStateProperty.all(
                      palette.primary,
                    ),
                    headingTextStyle: TextStyle(
                      color: palette.inverseText,
                      fontWeight: FontWeight.bold,
                    ),
                    columns: const [
                      DataColumn(label: Text('Student')),
                      DataColumn(label: Text('Subject')),
                      DataColumn(label: Text('Obtained')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Grade')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: results.map((item) {
                      final scoreController = TextEditingController(
                        text: item.score.toStringAsFixed(0),
                      );
                      final totalController = TextEditingController(
                        text: item.maxScore.toStringAsFixed(0),
                      );
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  item.studentId,
                                  style: TextStyle(
                                    color: palette.subtext,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(item.subject)),
                          DataCell(
                            SizedBox(
                              width: 84,
                              child: TextField(
                                controller: scoreController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 84,
                              child: TextField(
                                controller: totalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: palette.softCard,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _gradeLabel(item.score, item.maxScore),
                                style: TextStyle(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: () async {
                                final score = double.tryParse(
                                  scoreController.text,
                                );
                                final total = double.tryParse(
                                  totalController.text,
                                );
                                if (score == null ||
                                    total == null ||
                                    total <= 0) {
                                  Get.snackbar(
                                    'Invalid',
                                    'Obtained aur total marks valid hone chahiye.',
                                  );
                                  return;
                                }
                                await _provider.updateResult(
                                  resultId: item.id,
                                  score: score,
                                  maxScore: total,
                                );
                                _loadFiltered();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: palette.primary,
                                foregroundColor: palette.inverseText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    studentIdController.dispose();
    studentNameController.dispose();
    obtainedController.dispose();
    totalMarksController.dispose();
    super.dispose();
  }

  Widget _textField(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _subjectField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSubject,
      decoration: InputDecoration(
        labelText: 'Subject',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: _subjectsForClass(_className.value)
          .map(
            (subject) => DropdownMenuItem<String>(
              value: subject,
              child: Text(subject),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedSubject = value;
        });
      },
    );
  }

  Widget _buildMetricChip({
    required AppThemePalette palette,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.inverseText.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: palette.inverseText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> options, RxString selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: selected.value,
            underline: const SizedBox.shrink(),
            items: options
                .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                selected.value = val;
              }
            },
          ),
        ),
      ],
    );
  }
}
