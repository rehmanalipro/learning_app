import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../controllers/exam_schedule_controller.dart';
import '../models/exam_schedule_model.dart';

class StudentExamRoutineScreen extends StatelessWidget {
  const StudentExamRoutineScreen({super.key});

  Future<void> _refreshScreen() async {
    await Get.find<ExamScheduleController>().loadSchedules();
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
        'This datesheet PDF is not stored locally yet.',
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

  DateTime? _nextExam(List<ExamScheduleModel> schedules) {
    final now = DateTime.now();
    for (final item in schedules) {
      final examDay =
          DateTime(item.examDate.year, item.examDate.month, item.examDate.day);
      if (!examDay.isBefore(DateTime(now.year, now.month, now.day))) {
        return item.examDate;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final controller = Get.find<ExamScheduleController>();
    final classBinding = Get.find<ClassBindingService>();

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Exam Routine',
        subtitle: 'Your class schedule and datesheet',
      ),
      body: Obx(() {
        final className = classBinding.className.value.trim();
        final section = classBinding.section.value.trim().toUpperCase();
        final schedules = controller.schedulesForClass(
          className: className,
          section: section,
        )..sort((a, b) => a.examDate.compareTo(b.examDate));
        final nextExamDate = _nextExam(schedules);
        final nextExam = nextExamDate == null
            ? null
            : schedules.firstWhereOrNull((item) =>
                item.examDate.year == nextExamDate.year &&
                item.examDate.month == nextExamDate.month &&
                item.examDate.day == nextExamDate.day);

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
                      className.isEmpty || section.isEmpty
                          ? 'Class information not found. Please contact your teacher.'
                          : 'Class $className Section $section ka calendar, next exam summary, aur full room details yahan available hain.',
                      style: TextStyle(
                        color: palette.inverseText.withValues(alpha: 0.92),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (nextExam != null)
                    Container(
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
                            'Next Exam',
                            style: TextStyle(
                              color: palette.subtext,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nextExam.subject,
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(label: _dateLabel(nextExam.examDate)),
                              _InfoPill(label: nextExam.timeRangeLabel),
                              _InfoPill(label: nextExam.roomNumber),
                              _InfoPill(label: nextExam.blockName),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (nextExam != null) const SizedBox(height: 16),
                  if (schedules.isNotEmpty)
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: schedules.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = schedules[index];
                          return Container(
                            width: 88,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: palette.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${item.examDate.day}',
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                                Text(
                                  item.subject,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (schedules.isNotEmpty) const SizedBox(height: 18),
                  if (controller.isLoading.value)
                    const Center(child: CircularProgressIndicator())
                  else if (schedules.isEmpty)
                    _EmptyStateCard(
                      title: className.isEmpty || section.isEmpty
                          ? 'Class information not found'
                          : 'No exam routine available yet',
                      message: className.isEmpty || section.isEmpty
                          ? 'Class information not found. Please contact your teacher.'
                          : 'Teacher ya principal jab Class $className-$section ka schedule upload karein ge to yahan show hoga.',
                    )
                  else
                    ...schedules.map((item) {
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
                                  child: Text(
                                    item.subject,
                                    style: TextStyle(
                                      color: palette.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                _InfoPill(label: _dateLabel(item.examDate)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoPill(label: item.shiftLabel),
                                _InfoPill(label: item.timeRangeLabel),
                                _InfoPill(label: item.place),
                                _InfoPill(label: item.blockName),
                                _InfoPill(label: item.roomNumber),
                                _InfoPill(label: item.seatLabel),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Uploaded by: ${item.uploadedByName} (${item.uploadedByRole})',
                              style: TextStyle(color: palette.subtext),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: palette.text,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            if (item.dateSheetName != null) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () => _openPdf(item.dateSheetPath),
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
                                          item.dateSheetName!,
                                          style: TextStyle(color: palette.text),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

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
          Icon(Icons.calendar_month_outlined, size: 36, color: palette.primary),
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
