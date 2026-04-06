import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/firebase_storage_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../student/providers/student_provider.dart';
import '../models/homework_assignment_model.dart';
import '../providers/homework_provider.dart';

class TeacherSolutionScreen extends StatefulWidget {
  final String roleLabel;

  const TeacherSolutionScreen({
    super.key,
    this.roleLabel = 'Teacher',
  });

  @override
  State<TeacherSolutionScreen> createState() => _TeacherSolutionScreenState();
}

class _TeacherSolutionScreenState extends State<TeacherSolutionScreen> {
  final HomeworkProvider _homeworkProvider = Get.find<HomeworkProvider>();
  final StudentProvider _studentProvider = Get.find<StudentProvider>();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  HomeworkAssignmentModel? _selectedAssignment;
  bool _sendToWholeClass = true;
  String? _pdfName;
  String? _pdfPath;
  final Set<String> _selectedStudents = <String>{};

  Future<void> _refreshScreen() async {
    await Future.wait([
      _homeworkProvider.loadAll(),
      _studentProvider.loadStudents(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _teacherNameController.text =
        widget.roleLabel == 'Principal' ? 'Principal User' : 'Teacher User';
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openPdf(String? path) async {
    if (path == null || path.isEmpty) {
      Get.snackbar(
        'PDF unavailable',
        'This item has no local PDF path yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (path.startsWith('http')) {
      final uri = Uri.tryParse(path);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      Get.snackbar('Open failed', result.message);
    }
  }

  Future<void> _pickPdf(StateSetter setModalState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    setModalState(() {
      _pdfName = result.files.single.name;
      _pdfPath = result.files.single.path;
    });
  }

  List<String> _studentsForAssignment(HomeworkAssignmentModel assignment) {
    return _studentProvider.students
        .where((student) => student.className.trim() == assignment.className)
        .map((student) => student.name)
        .toList(growable: false);
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _sendSolution() async {
    final assignment = _selectedAssignment;
    if (assignment == null ||
        _teacherNameController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty ||
        _pdfName == null) {
      Get.snackbar(
        'Validation',
        'Assignment, teacher name, title aur solution PDF required hain.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!_sendToWholeClass && _selectedStudents.isEmpty) {
      Get.snackbar(
        'Select students',
        'Agar whole class off hai to kam az kam ek student select karein.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final wholeClassSelection = _sendToWholeClass;
    final uploadedPdfUrl = _pdfPath == null
        ? null
        : await _storageService.uploadFile(
            localPath: _pdfPath!,
            folder: 'homework/solutions',
            fileName: _pdfName,
          );

    await _homeworkProvider.addSolution(
      assignmentId: assignment.id,
      className: assignment.className,
      section: assignment.section,
      subject: assignment.subject,
      teacherName: _teacherNameController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      pdfName: _pdfName!,
      pdfPath: uploadedPdfUrl ?? _pdfPath,
      sendToWholeClass: wholeClassSelection,
      targetStudentNames: _selectedStudents.toList(growable: false),
    );

    _titleController.clear();
    _descriptionController.clear();
    _pdfName = null;
    _pdfPath = null;
    _selectedStudents.clear();
    _sendToWholeClass = true;
    Get.back();
    Get.snackbar(
      'Solution sent',
      wholeClassSelection
          ? 'Class ${assignment.className} ke tamam students ko solution bhej diya gaya.'
          : 'Selected students ko solution bhej diya gaya.',
      snackPosition: SnackPosition.BOTTOM,
    );
    setState(() {});
  }

  void _openSendSheet() {
    final palette = context.appPalette;
    _selectedAssignment ??=
        _homeworkProvider.assignments.isNotEmpty ? _homeworkProvider.assignments.first : null;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          final assignment = _selectedAssignment;
          final classStudents =
              assignment == null ? <String>[] : _studentsForAssignment(assignment);
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.roleLabel} Solution Panel',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aap homework task ka solution poori class ko ya selected students ko bhej sakte hain.',
                      style: TextStyle(color: palette.subtext),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HomeworkAssignmentModel>(
                      initialValue: assignment,
                      decoration: const InputDecoration(
                        labelText: 'Select Assignment',
                        border: OutlineInputBorder(),
                      ),
                      items: _homeworkProvider.assignments
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                '${item.title} | Class ${item.className}-${item.section}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedAssignment = value;
                          _sendToWholeClass = true;
                          _selectedStudents.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _teacherNameController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Solution Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Solution Detail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _sendToWholeClass,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send to whole class'),
                      subtitle: Text(
                        assignment == null
                            ? 'Select assignment first'
                            : 'One click me Class ${assignment.className} ke sab students ko solution chala jayega.',
                      ),
                      onChanged: assignment == null
                          ? null
                          : (value) {
                              setModalState(() {
                                _sendToWholeClass = value;
                                if (value) {
                                  _selectedStudents.clear();
                                }
                              });
                            },
                    ),
                    if (!_sendToWholeClass && classStudents.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Select students',
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: classStudents.map((studentName) {
                          final selected = _selectedStudents.contains(studentName);
                          return FilterChip(
                            label: Text(studentName),
                            selected: selected,
                            onSelected: (value) {
                              setModalState(() {
                                if (value) {
                                  _selectedStudents.add(studentName);
                                } else {
                                  _selectedStudents.remove(studentName);
                                }
                              });
                            },
                          );
                        }).toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _pickPdf(setModalState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, color: palette.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _pdfName ?? 'Attach solution PDF',
                                style: TextStyle(color: palette.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _sendSolution(),
                        icon: const Icon(Icons.send_outlined),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: palette.inverseText,
                        ),
                        label: const Text('Send Solution'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppScreenHeader(
        title: '${widget.roleLabel} Solutions',
        subtitle: 'Share solution PDFs by class or students',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSendSheet,
        backgroundColor: palette.primary,
        foregroundColor: palette.inverseText,
        icon: const Icon(Icons.send_outlined),
        label: const Text('Send'),
      ),
      body: AppRefreshScope(
        onRefresh: _refreshScreen,
        child: Obx(
          () => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
            maxWidth: 1040,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.announcementCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Teacher ek assignment ka solution poori class ko one click me ya selected students ko direct bhej sakta hai.',
                  style: TextStyle(
                    color: palette.inverseText.withValues(alpha: 0.92),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_homeworkProvider.solutions.isEmpty)
                _EmptyStateCard(
                  title: 'No solutions shared yet',
                  message: 'Send button se pehla solution PDF share karein.',
                )
              else
                ..._homeworkProvider.solutions.map((solution) {
                  final assignment = _homeworkProvider.assignments.firstWhereOrNull(
                    (item) => item.id == solution.assignmentId,
                  );
                  final targetLabel = solution.sendToWholeClass
                      ? 'Whole Class ${solution.className}-${solution.section}'
                      : solution.targetStudentNames.join(', ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    solution.title,
                                    style: TextStyle(
                                      color: palette.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Class ${solution.className}-${solution.section} | ${solution.subject}',
                                    style: TextStyle(color: palette.subtext),
                                  ),
                                ],
                              ),
                            ),
                            _CountBadge(
                              label: solution.sendToWholeClass
                                  ? 'Whole class'
                                  : '${solution.targetStudentNames.length} selected',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sent by: ${solution.teacherName}',
                          style: TextStyle(color: palette.subtext),
                        ),
                        if (assignment != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Task: ${assignment.title}',
                            style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Target: $targetLabel',
                          style: TextStyle(color: palette.text, height: 1.45),
                        ),
                        if (solution.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            solution.description,
                            style: TextStyle(color: palette.text, height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _openPdf(solution.pdfPath),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf_outlined, color: palette.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    solution.pdfName,
                                    style: TextStyle(color: palette.text),
                                  ),
                                ),
                                Text(
                                  _dateLabel(solution.createdAt),
                                  style: TextStyle(color: palette.subtext),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          ),
        ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;

  const _CountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb_outline, size: 36, color: palette.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.subtext, height: 1.5),
          ),
        ],
      ),
    );
  }
}
