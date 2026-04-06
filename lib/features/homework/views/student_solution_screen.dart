import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/homework_provider.dart';

class StudentSolutionScreen extends StatelessWidget {
  const StudentSolutionScreen({super.key});

  Future<void> _refreshScreen() async {
    await Future.wait([
      Get.find<HomeworkProvider>().loadAll(),
      Get.find<ProfileProvider>().loadProfiles(),
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
        'This solution does not have a local PDF path yet.',
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

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final homeworkProvider = Get.find<HomeworkProvider>();
    final profileProvider = Get.find<ProfileProvider>();

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Solutions',
        subtitle: 'Teacher and principal shared help',
      ),
      body: Obx(() {
        final studentProfile = profileProvider.profileFor('Student');
        final studentName = studentProfile.name.trim().toLowerCase();
        final studentClass = (studentProfile.className ?? '').trim();
        final studentSection = (studentProfile.section ?? '').trim().toUpperCase();

        final availableSolutions = homeworkProvider.solutions.where((solution) {
          final classMatch = solution.className.trim() == studentClass;
          final sectionMatch =
              solution.section.trim().toUpperCase() == studentSection;
          final targeted = solution.targetStudentNames
              .map((name) => name.trim().toLowerCase())
              .contains(studentName);
          return classMatch && sectionMatch && (solution.sendToWholeClass || targeted);
        }).toList(growable: false);

        return AppRefreshScope(
          onRefresh: _refreshScreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
            maxWidth: 980,
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
                  'Yahan aap ko sirf wohi solution nazar aayenge jo aapki class ko ya specifically aap ko bheje gaye hain.',
                  style: TextStyle(
                    color: palette.inverseText.withValues(alpha: 0.92),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (availableSolutions.isEmpty)
                _EmptyStateCard(
                  title: 'No solutions available yet',
                  message:
                      studentClass.isEmpty || studentSection.isEmpty
                          ? 'Profile me apni class aur section set karein.'
                          : 'Class $studentClass Section $studentSection ke solutions yahan show honge.',
                )
              else
                ...availableSolutions.map((solution) {
                  final assignment = homeworkProvider.assignments.firstWhereOrNull(
                    (item) => item.id == solution.assignmentId,
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
                                solution.title,
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _TargetBadge(
                              label: solution.sendToWholeClass
                                  ? 'Whole class'
                                  : 'Personal',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subject: ${solution.subject}',
                          style: TextStyle(color: palette.subtext),
                        ),
                        const SizedBox(height: 4),
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
                                const SizedBox(width: 10),
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
        );
      }),
    );
  }
}

class _TargetBadge extends StatelessWidget {
  final String label;

  const _TargetBadge({required this.label});

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
          Icon(Icons.menu_book_outlined, size: 36, color: palette.primary),
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
