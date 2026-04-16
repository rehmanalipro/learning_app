import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/attendance_entry_model.dart';
import '../providers/attendance_provider.dart';

class AttendanceFormScreen extends StatefulWidget {
  const AttendanceFormScreen({super.key});

  @override
  State<AttendanceFormScreen> createState() => _AttendanceFormScreenState();
}

class _AttendanceFormScreenState extends State<AttendanceFormScreen> {
  final AttendanceProvider _attendanceProvider = Get.find<AttendanceProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firebaseService.initialize();
    final profile = _profileProvider.profileFor('Student');
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _rollNumberController.text = profile.rollNumber ?? '';
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF15803D);
      case AttendanceStatus.absent:
        return const Color(0xFFB91C1C);
      case AttendanceStatus.pending:
        return const Color(0xFFB45309);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });
  }

  Future<void> _submitAttendance(String className, String section) async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _rollNumberController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation',
        'Name, email, and roll number are required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _attendanceProvider.submitAttendance(
        studentName: _nameController.text.trim(),
        rollNumber: _rollNumberController.text.trim(),
        className: className,
        section: section,
        email: _emailController.text.trim(),
        notes: _notesController.text.trim(),
      );

      _notesController.clear();
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      Get.snackbar(
        'Attendance submitted',
        'Teacher ke review panel me aapki request foran sync ho gayi hai.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Submission failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openAttendanceSheet() {
    final palette = context.appPalette;
    final profile = _profileProvider.profileFor('Student');
    final className = profile.className ?? '3';
    final section = profile.section ?? 'A';

    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _rollNumberController.text = profile.rollNumber ?? '';
    _notesController.clear();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
                  'Attendance Form',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Submit today attendance for Class $className Section $section.',
                  style: TextStyle(color: palette.subtext),
                ),
                const SizedBox(height: 16),
                _FormField(
                  label: 'Full Name',
                  controller: _nameController,
                  hintText: 'Enter student name',
                ),
                const SizedBox(height: 12),
                _FormField(
                  label: 'Email',
                  controller: _emailController,
                  hintText: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _StaticField(
                  label: 'Class',
                  value: className,
                ),
                const SizedBox(height: 12),
                _StaticField(
                  label: 'Section',
                  value: section,
                ),
                const SizedBox(height: 12),
                _FormField(
                  label: 'Roll No.',
                  controller: _rollNumberController,
                  hintText: 'Enter roll number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _StaticField(
                  label: 'Current Date',
                  value: _dateLabel(DateTime.now()),
                ),
                const SizedBox(height: 12),
                _StaticField(
                  label: 'Current Time',
                  value: _timeLabel(DateTime.now()),
                ),
                const SizedBox(height: 12),
                _FormField(
                  label: 'Notes',
                  controller: _notesController,
                  hintText: 'Optional note for teacher',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitAttendance(className, section),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.inverseText,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Attendance'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _refreshScreen() async {
    await Future.wait([
      _attendanceProvider.loadEntries(),
      _profileProvider.loadProfiles(),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final studentProfile = _profileProvider.profileFor('Student');

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Attendance',
        subtitle: 'Submit and review your attendance',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAttendanceSheet,
        backgroundColor: palette.primary,
        foregroundColor: palette.inverseText,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        final currentUid = (_firebaseService.currentUser?.uid ?? '').trim();
        final studentEntries = _attendanceProvider.attendanceEntries.where((entry) {
          final sameStudent =
              (currentUid.isNotEmpty &&
                  entry.studentUid.trim().isNotEmpty &&
                  entry.studentUid.trim() == currentUid) ||
              (entry.email.trim().toLowerCase() ==
                      studentProfile.email.trim().toLowerCase() &&
                  entry.studentName.trim().toLowerCase() ==
                      studentProfile.name.trim().toLowerCase());
          final sameClass =
              (studentProfile.className == null ||
                  studentProfile.className!.isEmpty ||
                  entry.className == studentProfile.className);
          final sameSection =
              (studentProfile.section == null ||
                  studentProfile.section!.isEmpty ||
                  entry.section.toUpperCase() ==
                      studentProfile.section!.toUpperCase());
          return sameStudent && sameClass && sameSection;
        }).toList(growable: false);

        final monthlyEntries = studentEntries
            .where((entry) => _isSameMonth(entry.submittedAt, _selectedMonth))
            .toList(growable: false)
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

        final presentCount = monthlyEntries
            .where((entry) => entry.status == AttendanceStatus.present)
            .length;
        final absentCount = monthlyEntries
            .where((entry) => entry.status == AttendanceStatus.absent)
            .length;

        return AppRefreshScope(
          onRefresh: _refreshScreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
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
                  'Check your full month attendance, teacher decision time, and submit a new request with the + button.',
                  style: TextStyle(
                    color: palette.inverseText.withValues(alpha: 0.92),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: _SummaryCard(
                      title: 'Present',
                      value: '$presentCount days',
                      accentColor: const Color(0xFF15803D),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: _SummaryCard(
                      title: 'Absent',
                      value: '$absentCount days',
                      accentColor: const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickMonth,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _monthLabel(_selectedMonth),
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Change',
                        style: TextStyle(color: palette.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Monthly Attendance',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (monthlyEntries.isEmpty)
                _EmptyStateCard(
                  title: 'No attendance record found',
                  message:
                      'Attendance for ${_monthLabel(_selectedMonth)} will appear here with teacher status and time.',
                )
              else
                ...monthlyEntries.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                                '${entry.studentName} • Roll ${entry.rollNumber}',
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(entry.status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(entry.status),
                                style: TextStyle(
                                  color: _statusColor(entry.status),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Class ${entry.className} | Section ${entry.section}',
                          style: TextStyle(color: palette.subtext),
                        ),
                        if ((entry.notes ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Note: ${entry.notes!.trim()}',
                            style: TextStyle(
                              color: palette.subtext,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Submitted: ${_dateLabel(entry.submittedAt)} at ${_timeLabel(entry.submittedAt)}',
                          style: TextStyle(color: palette.subtext),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.markedAt == null
                              ? 'Teacher review: Pending'
                              : 'Teacher marked on ${_dateLabel(entry.markedAt!)} at ${_timeLabel(entry.markedAt!)}',
                          style: TextStyle(
                            color: entry.markedAt == null
                                ? const Color(0xFFB45309)
                                : palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          ),
          ),
        );
      }),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: palette.text)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: palette.subtext),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaticField extends StatelessWidget {
  final String label;
  final String value;

  const _StaticField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: palette.text)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            value,
            style: TextStyle(color: palette.text),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
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
              color: palette.subtext,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
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
          Icon(Icons.event_note_outlined, size: 36, color: palette.primary),
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
