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
import '../controllers/exam_schedule_controller.dart';

class TeacherExamRoutineScreen extends StatefulWidget {
  final String roleLabel;

  const TeacherExamRoutineScreen({
    super.key,
    this.roleLabel = 'Teacher',
  });

  @override
  State<TeacherExamRoutineScreen> createState() =>
      _TeacherExamRoutineScreenState();
}

class _TeacherExamRoutineScreenState extends State<TeacherExamRoutineScreen> {
  final ExamScheduleController _controller = Get.find<ExamScheduleController>();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final TextEditingController _uploaderController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _seatController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _classes = const ['1', '2', '3', '4', '5'];
  final List<String> _sections = const ['A', 'B', 'C'];
  String _selectedClass = '1';
  String _selectedSection = 'A';
  String _selectedSubject = 'English';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String? _dateSheetName;
  String? _dateSheetPath;

  @override
  void initState() {
    super.initState();
    _uploaderController.text =
        widget.roleLabel == 'Principal' ? 'Principal User' : 'Teacher User';
    _selectedSubject = _controller.subjectsForClass(_selectedClass).first;
  }

  @override
  void dispose() {
    _uploaderController.dispose();
    _placeController.dispose();
    _blockController.dispose();
    _roomController.dispose();
    _seatController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _timeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _shiftFromTime(TimeOfDay time) {
    return time.hour < 12 ? 'Morning' : 'Evening';
  }

  Future<void> _pickDate(StateSetter setModalState) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setModalState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({
    required StateSetter setModalState,
    required bool isStart,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setModalState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _pickDateSheet(StateSetter setModalState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    setModalState(() {
      _dateSheetName = result.files.single.name;
      _dateSheetPath = result.files.single.path;
    });
  }

  Future<void> _openPdf(String? path) async {
    if (path == null || path.isEmpty) {
      Get.snackbar(
        'PDF unavailable',
        'This routine does not have a local datesheet file yet.',
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

  Future<void> _publishRoutine() async {
    final startMinutes = _minutesOf(_startTime);
    final endMinutes = _minutesOf(_endTime);

    if (_uploaderController.text.trim().isEmpty ||
        _placeController.text.trim().isEmpty ||
        _blockController.text.trim().isEmpty ||
        _roomController.text.trim().isEmpty ||
        _seatController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation',
        'Uploader, place, block, room, aur seat details zaroori hain.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (endMinutes <= startMinutes) {
      Get.snackbar(
        'Invalid time',
        'Exam ka end time start time se baad hona chahiye.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final uploadedDateSheetUrl = _dateSheetPath == null
        ? null
        : await _storageService.uploadFile(
            localPath: _dateSheetPath!,
            folder: 'exams/datesheets',
            fileName: _dateSheetName,
          );

    final error = await _controller.addSchedule(
      className: _selectedClass,
      section: _selectedSection,
      subject: _selectedSubject,
      uploadedByName: _uploaderController.text.trim(),
      uploadedByRole: widget.roleLabel,
      examDate: _selectedDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      shiftLabel: _shiftFromTime(_startTime),
      place: _placeController.text.trim(),
      blockName: _blockController.text.trim(),
      roomNumber: _roomController.text.trim(),
      seatLabel: _seatController.text.trim(),
      description: _descriptionController.text.trim(),
      dateSheetName: _dateSheetName,
      dateSheetPath: uploadedDateSheetUrl ?? _dateSheetPath,
    );

    if (error != null) {
      Get.snackbar('Schedule conflict', error, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    _placeController.clear();
    _blockController.clear();
    _roomController.clear();
    _seatController.clear();
    _descriptionController.clear();
    _dateSheetName = null;
    _dateSheetPath = null;
    Get.back();
    Get.snackbar(
      'Exam scheduled',
      'Class $_selectedClass-$_selectedSection ke students ko exam routine mil gaya.',
      snackPosition: SnackPosition.BOTTOM,
    );
    setState(() {});
  }

  void _openScheduleSheet() {
    final palette = context.appPalette;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          final subjects = _controller.subjectsForClass(_selectedClass);
          if (!subjects.contains(_selectedSubject)) {
            _selectedSubject = subjects.first;
          }
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
                      '${widget.roleLabel} Exam Scheduler',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Class-specific subjects, exact timing, seat/block, aur overlap safety validation included hai.',
                      style: TextStyle(color: palette.subtext),
                    ),
                    const SizedBox(height: 16),
                    _DropdownField(
                      label: 'Class',
                      value: _selectedClass,
                      items: _classes,
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          _selectedClass = value;
                          _selectedSubject =
                              _controller.subjectsForClass(value).first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownField(
                      label: 'Section',
                      value: _selectedSection,
                      items: _sections,
                      onChanged: (value) =>
                          setModalState(() => _selectedSection = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _uploaderController,
                      decoration: const InputDecoration(
                        labelText: 'Uploaded By',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DropdownField(
                      label: 'Subject',
                      value: _selectedSubject,
                      items: subjects,
                      onChanged: (value) =>
                          setModalState(() => _selectedSubject = value!),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _pickDate(setModalState),
                      child: _InfoTile(
                        icon: Icons.calendar_month_outlined,
                        text: 'Exam Date: ${_dateLabel(_selectedDate)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(
                              setModalState: setModalState,
                              isStart: true,
                            ),
                            child: _InfoTile(
                              icon: Icons.schedule_outlined,
                              text: 'Start: ${_timeLabel(_startTime)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(
                              setModalState: setModalState,
                              isStart: false,
                            ),
                            child: _InfoTile(
                              icon: Icons.timelapse_outlined,
                              text: 'End: ${_timeLabel(_endTime)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _placeController,
                      decoration: const InputDecoration(
                        labelText: 'Place / Campus',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _blockController,
                            decoration: const InputDecoration(
                              labelText: 'Block',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _roomController,
                            decoration: const InputDecoration(
                              labelText: 'Room Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _seatController,
                      decoration: const InputDecoration(
                        labelText: 'Seat / Row / Roll Range',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _pickDateSheet(setModalState),
                      child: _InfoTile(
                        icon: Icons.upload_file_outlined,
                        text: _dateSheetName ?? 'Upload datesheet PDF (optional)',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _publishRoutine(),
                        icon: const Icon(Icons.publish_outlined),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: palette.inverseText,
                        ),
                        label: const Text('Publish Exam Routine'),
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
        title: '${widget.roleLabel} Exam Routine',
        subtitle: 'Schedule class-wise exam datesheets',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScheduleSheet,
        backgroundColor: palette.primary,
        foregroundColor: palette.inverseText,
        icon: const Icon(Icons.event_note_outlined),
        label: const Text('Schedule'),
      ),
      body: AppRefreshScope(
        onRefresh: _controller.loadSchedules,
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
                    'Ab routine me class-specific subjects, exact start/end time, place, block, room, seat labels, PDF datesheet, aur overlap validation sab included hain.',
                    style: TextStyle(
                      color: palette.inverseText.withValues(alpha: 0.92),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_controller.isLoading.value)
                  const Center(child: CircularProgressIndicator())
                else if (_controller.schedules.isEmpty)
                  const _EmptyStateCard(
                    title: 'No exam scheduled yet',
                    message: 'Schedule button se first exam routine publish karein.',
                  )
                else
                  ..._controller.schedules.map((item) {
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
                                      item.subject,
                                      style: TextStyle(
                                        color: palette.text,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Class ${item.className}-${item.section} | ${item.shiftLabel}',
                                      style: TextStyle(color: palette.subtext),
                                    ),
                                  ],
                                ),
                              ),
                              _MetaBadge(label: _dateLabel(item.examDate)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Time: ${item.timeRangeLabel}',
                            style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaBadge(label: item.place),
                              _MetaBadge(label: item.blockName),
                              _MetaBadge(label: item.roomNumber),
                              _MetaBadge(label: item.seatLabel),
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
                              style: TextStyle(color: palette.text, height: 1.5),
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
                                    Icon(Icons.picture_as_pdf_outlined, color: palette.primary),
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
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: palette.text)),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;

  const _MetaBadge({required this.label});

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
