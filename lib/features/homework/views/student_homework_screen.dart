import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/homework_submission_model.dart';
import '../providers/homework_provider.dart';

class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  final HomeworkProvider _homeworkProvider = Get.find<HomeworkProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final ClassBindingService _classBinding = Get.find<ClassBindingService>();
  int _selectedTabIndex = 0;

  Future<void> _refreshScreen() async {
    await Future.wait([
      _homeworkProvider.loadAll(),
      _profileProvider.loadProfiles(),
    ]);
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _openPdf(String? path) async {
    if (path == null || path.isEmpty) {
      Get.snackbar(
        'PDF unavailable',
        'This demo item has no local PDF path yet.',
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
      Get.snackbar(
        'Open failed',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TopTabButton(
              label: 'Teacher Tasks',
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TopTabButton(
              label: 'My Uploads',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignments(BuildContext context) {
    final palette = context.appPalette;
    final studentClass = _classBinding.className.value.trim();
    final studentSection = _classBinding.section.value.trim().toUpperCase();

    if (studentClass.isEmpty || studentSection.isEmpty) {
      return const _EmptyStateCard(
        title: 'Class information not found',
        message: 'Class information not found. Please contact your teacher.',
      );
    }

    final assignments = _homeworkProvider.assignments
        .where(
          (item) =>
              item.className.trim() == studentClass &&
              item.section.trim().toUpperCase() == studentSection,
        )
        .toList(growable: false);

    if (assignments.isEmpty) {
      return _EmptyStateCard(
        title: 'No task for your class yet',
        message:
            'Only homework for Class $studentClass Section $studentSection will appear here.',
      );
    }

    return Column(
      children: assignments.map((assignment) {
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
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Text(
                    _dateLabel(assignment.createdAt),
                    style: TextStyle(color: palette.subtext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Class ${assignment.className} | Section ${assignment.section} | ${assignment.subject}',
                style: TextStyle(color: palette.subtext),
              ),
              const SizedBox(height: 4),
              Text(
                'Teacher: ${assignment.teacherName}',
                style: TextStyle(color: palette.subtext),
              ),
              const SizedBox(height: 4),
              Text(
                'Due: ${_dateLabel(assignment.dueDate)}',
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (assignment.details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  assignment.details,
                  style: TextStyle(color: palette.text, height: 1.5),
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openPdf(assignment.pdfPath),
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
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: palette.primary,
                      ),
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(
                    AppRoutes.studentHomeworkSubmit,
                    arguments: assignment,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.inverseText,
                  ),
                  child: const Text('Upload Completed Work'),
                ),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildMyUploads(BuildContext context) {
    final palette = context.appPalette;
    final currentStudentName = _profileProvider.profileFor('Student').name.trim();
    final myUploads = _homeworkProvider.submissions
        .where(
          (item) =>
              item.studentName.trim().toLowerCase() ==
              currentStudentName.toLowerCase(),
        )
        .toList(growable: false);

    if (myUploads.isEmpty) {
      return const _EmptyStateCard(
        title: 'No upload submitted yet',
        message: 'Your uploaded homework PDFs will appear here.',
      );
    }

    return Column(
      children: myUploads.map((submission) {
        final assignment = _homeworkProvider.assignments.firstWhereOrNull(
          (item) => item.id == submission.assignmentId,
        );
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
                children: [
                  Expanded(
                    child: Text(
                      assignment?.title ?? 'Submitted Homework',
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusBadge(status: submission.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Class ${submission.className} | Section ${submission.section} | ${submission.subject}',
                style: TextStyle(color: palette.subtext),
              ),
              const SizedBox(height: 4),
              Text(
                'Teacher: ${submission.teacherName}',
                style: TextStyle(color: palette.subtext),
              ),
              const SizedBox(height: 4),
              Text(
                'Uploaded: ${_dateLabel(submission.submittedAt)}',
                style: TextStyle(color: palette.subtext),
              ),
              if (submission.answerText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  submission.answerText,
                  style: TextStyle(color: palette.text, height: 1.5),
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openPdf(submission.pdfPath),
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
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          submission.pdfName,
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                      Icon(Icons.open_in_new, color: palette.subtext),
                    ],
                  ),
                ),
              ),
              if (submission.teacherRemarks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Teacher Remarks: ${submission.teacherRemarks}',
                  style: TextStyle(color: palette.primary),
                ),
              ],
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Homework',
        subtitle: 'Tasks, uploads, and feedback',
      ),
      body: AppRefreshScope(
        onRefresh: _refreshScreen,
        child: Obx(
          () => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.announcementCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _selectedTabIndex == 0
                      ? 'This section shows homework tasks assigned by your teacher.'
                      : 'This section shows your submitted homework and teacher feedback.',
                  style: TextStyle(
                    color: palette.inverseText.withValues(alpha: 0.92),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_selectedTabIndex == 0)
                _buildAssignments(context)
              else
                _buildMyUploads(context),
            ],
          ),
          ),
        ),
        ),
      ),
    );
  }
}

class _TopTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? palette.inverseText : palette.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final HomeworkSubmissionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isReviewed = status == HomeworkSubmissionStatus.reviewed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isReviewed ? const Color(0xFFE7F8EE) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isReviewed ? 'Reviewed' : 'Submitted',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isReviewed ? const Color(0xFF15803D) : const Color(0xFFB45309),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({
    required this.title,
    required this.message,
  });

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
          Icon(Icons.inbox_outlined, size: 36, color: palette.primary),
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
