import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/services/class_roster_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../models/attendance_entry_model.dart';
import '../providers/attendance_provider.dart';
import '../services/attendance_service.dart';

enum _ReviewStatusFilter { all, present, absent }

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceProvider _attendanceProvider = Get.find<AttendanceProvider>();
  final ClassBindingService _classBinding = Get.find<ClassBindingService>();
  final ClassRosterService _rosterService = Get.find<ClassRosterService>();
  final AttendanceService _attendanceService = Get.find<AttendanceService>();

  late final TabController _tabController;

  final Map<String, AttendanceStatus> _statusMap = {};
  bool _isSubmitting = false;

  final List<String> _classes = const ['All', '1', '2', '3', '4', '5'];
  final List<String> _sections = const ['All', 'A', 'B', 'C'];
  String _selectedClass = 'All';
  String _selectedSection = 'All';
  _ReviewStatusFilter _selectedReviewFilter = _ReviewStatusFilter.all;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final boundClass = _classBinding.className.value.trim();
    final boundSection = _classBinding.section.value.trim().toUpperCase();
    if (_classes.contains(boundClass)) {
      _selectedClass = boundClass;
    }
    if (_sections.contains(boundSection)) {
      _selectedSection = boundSection;
    }
    _attendanceProvider.loadEntries();
    _loadRoster();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoster() async {
    final className = _classBinding.className.value;
    final section = _classBinding.section.value;
    if (className.isEmpty || section.isEmpty) return;
    await _rosterService.loadRoster(className: className, section: section);
    setState(() {
      for (final student in _rosterService.roster) {
        final uid = student['uid'] as String? ?? '';
        if (uid.isNotEmpty && !_statusMap.containsKey(uid)) {
          _statusMap[uid] = AttendanceStatus.present;
        }
      }
    });
  }

  Future<void> _submitAttendance() async {
    final roster = _rosterService.roster.toList();
    if (roster.isEmpty) return;
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    setState(() => _isSubmitting = true);
    try {
      await _attendanceService.bulkMarkAttendance(
        roster: roster,
        date: date,
        statusMap: Map.from(_statusMap),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit attendance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
      if (_endDate.isBefore(_startDate)) _endDate = _startDate;
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
      _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
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
    final itemDate = DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );
    return !itemDate.isBefore(_startDate) && !itemDate.isAfter(_endDate);
  }

  bool _matchesReviewFilter(AttendanceEntryModel entry) {
    switch (_selectedReviewFilter) {
      case _ReviewStatusFilter.present:
        return entry.status == AttendanceStatus.present;
      case _ReviewStatusFilter.absent:
        return entry.status == AttendanceStatus.absent;
      case _ReviewStatusFilter.all:
        return true;
    }
  }

  String _reviewFilterLabel() {
    switch (_selectedReviewFilter) {
      case _ReviewStatusFilter.present:
        return 'Present only';
      case _ReviewStatusFilter.absent:
        return 'Absent only';
      case _ReviewStatusFilter.all:
        return 'All requests';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: _buildAppBar(palette),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMarkTab(palette), _buildReviewTab(palette)],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic palette) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: palette.inverseText,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Attendance',
            style: TextStyle(
              color: palette.inverseText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Teacher attendance panel',
            style: TextStyle(
              color: palette.inverseText.withValues(alpha: 0.92),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primary, palette.accent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: palette.inverseText,
        unselectedLabelColor: palette.inverseText.withValues(alpha: 0.6),
        indicatorColor: palette.inverseText,
        tabs: const [
          Tab(text: 'Mark Attendance'),
          Tab(text: 'Review'),
        ],
      ),
    );
  }

  Widget _buildMarkTab(dynamic palette) {
    return Obx(() {
      if (_rosterService.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final roster = _rosterService.roster;
      if (roster.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No students in your class yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.text, fontSize: 16),
            ),
          ),
        );
      }
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: roster.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, thickness: 0.8),
              itemBuilder: (context, index) {
                final student = roster[index];
                final uid = student['uid'] as String? ?? '';
                final isPresent =
                    (_statusMap[uid] ?? AttendanceStatus.present) ==
                    AttendanceStatus.present;
                return Container(
                  color: palette.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'] as String? ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Roll ${student['rollNumber'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AttendanceToggle(
                        isPresent: isPresent,
                        onChanged: (present) {
                          setState(() {
                            _statusMap[uid] = present
                                ? AttendanceStatus.present
                                : AttendanceStatus.absent;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildReviewTab(dynamic palette) {
    final entries = _attendanceProvider.attendanceEntries;
    return AppRefreshScope(
      onRefresh: _attendanceProvider.loadEntries,
      child: Obx(() {
        final matchingEntries =
            entries
                .where((entry) {
                  final classMatch =
                      _selectedClass == 'All' ||
                      entry.className == _selectedClass;
                  final sectionMatch =
                      _selectedSection == 'All' ||
                      entry.section == _selectedSection;
                  final dateMatch = _isWithinRange(entry.submittedAt);
                  return classMatch && sectionMatch && dateMatch;
                })
                .toList(growable: false)
              ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

        final filteredEntries = matchingEntries
            .where(_matchesReviewFilter)
            .toList(growable: false);

        final presentCount = matchingEntries
            .where((e) => e.status == AttendanceStatus.present)
            .length;
        final absentCount = matchingEntries
            .where((e) => e.status == AttendanceStatus.absent)
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
                                setState(() => _selectedClass = value);
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
                                setState(() => _selectedSection = value);
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Present',
                          value: '$presentCount',
                          color: const Color(0xFF15803D),
                          isSelected:
                              _selectedReviewFilter ==
                              _ReviewStatusFilter.present,
                          onTap: () {
                            setState(() {
                              _selectedReviewFilter =
                                  _selectedReviewFilter ==
                                          _ReviewStatusFilter.present
                                      ? _ReviewStatusFilter.all
                                      : _ReviewStatusFilter.present;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Absent',
                          value: '$absentCount',
                          color: const Color(0xFFB91C1C),
                          isSelected:
                              _selectedReviewFilter ==
                              _ReviewStatusFilter.absent,
                          onTap: () {
                            setState(() {
                              _selectedReviewFilter =
                                  _selectedReviewFilter ==
                                          _ReviewStatusFilter.absent
                                      ? _ReviewStatusFilter.all
                                      : _ReviewStatusFilter.absent;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Showing: ${_reviewFilterLabel()}',
                        style: TextStyle(
                          color: palette.subtext,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _selectedReviewFilter == _ReviewStatusFilter.all
                            ? null
                            : () {
                                setState(() {
                                  _selectedReviewFilter =
                                      _ReviewStatusFilter.all;
                                });
                              },
                        child: const Text('Show all'),
                      ),
                    ],
                  ),
                  if (matchingEntries.any(
                    (entry) => entry.status == AttendanceStatus.pending,
                  ))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pending requests default list me show hoti rahengi jab filter All ho.',
                        style: TextStyle(
                          color: palette.subtext,
                          fontSize: 12,
                        ),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
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
                                    if ((entry.notes ?? '').trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Note: ${entry.notes!.trim()}',
                                        style: TextStyle(
                                          color: palette.subtext,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
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
                                  value:
                                      entry.status == AttendanceStatus.present,
                                  onChanged: (_) => _attendanceProvider
                                      .updateAttendanceStatus(
                                        entry.id,
                                        AttendanceStatus.present,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Checkbox(
                                  value:
                                      entry.status == AttendanceStatus.absent,
                                  onChanged: (_) => _attendanceProvider
                                      .updateAttendanceStatus(
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
    );
  }
}

class _AttendanceToggle extends StatelessWidget {
  final bool isPresent;
  final ValueChanged<bool> onChanged;

  const _AttendanceToggle({required this.isPresent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: 'P',
          selected: isPresent,
          selectedColor: const Color(0xFF15803D),
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 8),
        _ToggleChip(
          label: 'A',
          selected: !isPresent,
          selectedColor: const Color(0xFFB91C1C),
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? selectedColor
              : selectedColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : selectedColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
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
          Text(label, style: TextStyle(fontSize: 11, color: palette.subtext)),
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
  final bool isSelected;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.14),
              width: isSelected ? 1.4 : 1,
            ),
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
        ),
      ),
    );
  }
}
