import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/firebase_storage_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/homework_assignment_model.dart';
import '../providers/homework_provider.dart';

class SubmitHomeworkScreen extends StatefulWidget {
  const SubmitHomeworkScreen({super.key});

  @override
  State<SubmitHomeworkScreen> createState() => _SubmitHomeworkScreenState();
}

class _SubmitHomeworkScreenState extends State<SubmitHomeworkScreen> {
  final HomeworkProvider _homeworkProvider = Get.find<HomeworkProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  String? _pdfName;
  String? _pdfPath;
  bool _isSubmitting = false;

  HomeworkAssignmentModel get assignment =>
      Get.arguments as HomeworkAssignmentModel;

  @override
  void initState() {
    super.initState();
    _studentNameController.text = _profileProvider.profileFor('Student').name;
  }

  Future<void> _openAssignmentPdf() async {
    if (assignment.pdfPath == null || assignment.pdfPath!.isEmpty) {
      Get.snackbar(
        'PDF unavailable',
        'This assignment PDF is not available.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (assignment.pdfPath!.startsWith('http')) {
      final uri = Uri.tryParse(assignment.pdfPath!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final result = await OpenFilex.open(assignment.pdfPath!);
    if (result.type != ResultType.done) {
      Get.snackbar(
        'Open failed',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _pdfName = result.files.single.name;
      _pdfPath = result.files.single.path;
    });
  }

  Future<void> _submit() async {
    if (_studentNameController.text.trim().isEmpty || _pdfName == null) {
      Get.snackbar(
        'Validation',
        'Student name and PDF are required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uploadedPdfUrl = _pdfPath == null
          ? null
          : await _storageService.uploadFile(
              localPath: _pdfPath!,
              folder: 'homework/submissions',
              fileName: _pdfName,
            );

      await _homeworkProvider.submitHomework(
        assignmentId: assignment.id,
        studentName: _studentNameController.text.trim(),
        className: assignment.className,
        section: assignment.section,
        subject: assignment.subject,
        teacherName: assignment.teacherName,
        answerText: _answerController.text.trim(),
        pdfName: _pdfName!,
        pdfPath: uploadedPdfUrl ?? _pdfPath,
      );

      Get.back();
      Get.snackbar(
        'Homework submitted',
        'Your submission has been sent to the teacher.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Submit Homework',
        subtitle: 'Upload completed work for review',
      ),
      body: SingleChildScrollView(
        child: ResponsiveContent(
          maxWidth: 760,
          child: Column(
          children: [
            _ReadOnlyCard(
              title: 'Assignment Details',
              lines: [
                'Class: ${assignment.className}',
                'Section: ${assignment.section}',
                'Subject: ${assignment.subject}',
                'Teacher: ${assignment.teacherName}',
                'Due: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}',
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openAssignmentPdf,
              borderRadius: BorderRadius.circular(12),
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
                        assignment.pdfName,
                        style: TextStyle(color: palette.text),
                      ),
                    ),
                    Icon(Icons.open_in_new, color: palette.subtext),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Field(controller: _studentNameController, label: 'Student Name'),
            const SizedBox(height: 14),
            _Field(
              controller: _answerController,
              label: 'Add homework note',
              maxLines: 5,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickPdf,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: palette.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pdfName ?? 'Attach completed PDF',
                        style: TextStyle(color: palette.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.inverseText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
      ),
    );
  }
}

class _ReadOnlyCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _ReadOnlyCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
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
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: TextStyle(color: palette.text)),
            ),
          ),
        ],
      ),
    );
  }
}
