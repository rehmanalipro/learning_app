import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../models/attendance_entry_model.dart';
import '../providers/attendance_provider.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final AttendanceProvider _attendanceProvider = Get.find<AttendanceProvider>();
  final List<String> _classes = const ['All', '1', '2', '3', '4', '5'];
  final List<String> _sections = const ['All', 'A', 'B', 'C'];

  String _selectedClass = 'All';
  String _selectedSection = 'All';
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      _endDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      );
    });
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

  bool _isWithinRange(DateTime date) {
    final itemDate = DateTime(date.year, date.month, date.day, date.hour, date.minute);
    return !itemDate.isBefore(_startDate) && !itemDate.isAfter(_endDate);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final entries = _attendanceProvider.attendanceEntries;

    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: const AppScreenHeader(
        title: 'Attendance',
        subtitle: 'Teacher attendance review panel',
      ),
      body: AppRefreshScope(
        onRefresh: _attendanceProvider.loadEntries,
        child: Obx(() {
        final filteredEntries = entries.where((entry) {
          final classMatch =
              _selectedClass == 'All' || entry.className == _selectedClass;
          final sectionMatch = _selectedSection == 'All' ||
              entry.section == _selectedSection;
          final dateMatch = _isWithinRange(entry.submittedAt);
          return classMatch && sectionMatch && dateMatch;
        }).toList(growable: false)
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

        final presentCount = filteredEntries
            .where((entry) => entry.status == AttendanceStatus.present)
            .length;
        final absentCount = filteredEntries
            .where((entry) => entry.status == AttendanceStatus.absent)
            .length;
        final pendingCount = filteredEntries
            .where((entry) => entry.status == AttendanceStatus.pending)
            .length;

        return Column(
          children: [
            Container(
              color: palette.primary,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FilterBox(
                          label: 'Class',
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedClass,
                              dropdownColor: palette.surface,
                              isExpanded: true,
                              items: _classes
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item == 'All'
                                            ? 'All Classes'
                                            : 'Class $item',
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedClass = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterBox(
                          label: 'Section',
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSection,
                              dropdownColor: palette.surface,
                              isExpanded: true,
                              items: _sections
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedSection = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickStartDate(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From',
                                  style: TextStyle(
                                    color: palette.subtext,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateLabel(_startDate),
                                  style: TextStyle(
                                    color: palette.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickEndDate(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To',
                                  style: TextStyle(
                                    color: palette.subtext,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateLabel(_endDate),
                                  style: TextStyle(
                                    color: palette.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: palette.surface,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Present',
                      value: '$presentCount',
                      color: const Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Absent',
                      value: '$absentCount',
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pending',
                      value: '$pendingCount',
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: palette.isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFDBE6FF),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Student / Roll',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Date & Time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'P',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'A',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No attendance found for this class, section, and date range.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filteredEntries.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, thickness: 0.8),
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        return Container(
                          color: palette.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.studentName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: palette.text,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Roll ${entry.rollNumber}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: palette.text,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _dateLabel(entry.submittedAt),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _timeLabel(entry.submittedAt),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.subtext,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Checkbox(
                                  value: entry.status == AttendanceStatus.present,
                                  onChanged: (_) =>
                                      _attendanceProvider.updateAttendanceStatus(
                                    entry.id,
                                    AttendanceStatus.present,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Checkbox(
                                  value: entry.status == AttendanceStatus.absent,
                                  onChanged: (_) =>
                                      _attendanceProvider.updateAttendanceStatus(
                                    entry.id,
                                    AttendanceStatus.absent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: palette.subtext,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
