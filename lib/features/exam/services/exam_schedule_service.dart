import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/exam_schedule_model.dart';

class ExamScheduleService extends GetxService {
  static const _collection = 'exam_schedules';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<ExamScheduleModel> schedules = <ExamScheduleModel>[].obs;
  final RxBool isLoading = false.obs;

  final Map<String, List<String>> classSubjects = const {
    '1': ['English', 'Mathematics', 'General Knowledge'],
    '2': ['English Grammar', 'Urdu', 'General Science'],
    '3': ['English', 'Mathematics', 'Islamiyat', 'Science'],
    '4': ['English', 'Social Studies', 'Science', 'Urdu'],
    '5': ['English', 'Mathematics', 'Computer', 'Science'],
  };

  List<String> subjectsForClass(String className) {
    return classSubjects[className] ?? const ['English'];
  }

  Future<void> loadSchedules() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<ExamScheduleModel>(
        path: _collection,
        fromMap: ExamScheduleModel.fromMap,
      );
      if (fetched.isEmpty && schedules.isEmpty) {
        final demo = _demoSchedule();
        await _store.setCollectionDocument(
          collectionPath: _collection,
          id: demo.id,
          data: demo.toMap(),
        );
        schedules.value = [demo];
      } else {
        schedules.value = fetched..sort((a, b) => a.examDate.compareTo(b.examDate));
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool hasOverlap({
    required String className,
    required String section,
    required DateTime examDate,
    required int startMinutes,
    required int endMinutes,
  }) {
    return schedules.any((item) {
      final sameClass = item.className.trim() == className.trim();
      final sameSection =
          item.section.trim().toUpperCase() == section.trim().toUpperCase();
      final sameDate = item.examDate.year == examDate.year &&
          item.examDate.month == examDate.month &&
          item.examDate.day == examDate.day;
      final overlap =
          startMinutes < item.endMinutes && endMinutes > item.startMinutes;
      return sameClass && sameSection && sameDate && overlap;
    });
  }

  ExamScheduleModel _demoSchedule() {
    return ExamScheduleModel(
      id: 'exam-1',
      className: '3',
      section: 'A',
      subject: 'English',
      uploadedByName: 'Sara Ahmed',
      uploadedByRole: 'Teacher',
      examDate: DateTime.now().add(const Duration(days: 6)),
      startMinutes: 9 * 60,
      endMinutes: 11 * 60,
      shiftLabel: 'Morning',
      place: 'Main Campus',
      blockName: 'Block B',
      roomNumber: 'Room 12',
      seatLabel: 'Front Rows 1-10',
      description: 'Reach 20 minutes early with admit card and blue pen.',
      dateSheetName: 'class_3_midterm_datesheet.pdf',
      createdAt: DateTime.now(),
    );
  }

  Future<String?> addSchedule({
    required String className,
    required String section,
    required String subject,
    required String uploadedByName,
    required String uploadedByRole,
    required DateTime examDate,
    required int startMinutes,
    required int endMinutes,
    required String shiftLabel,
    required String place,
    required String blockName,
    required String roomNumber,
    required String seatLabel,
    required String description,
    String? dateSheetName,
    String? dateSheetPath,
  }) async {
    if (hasOverlap(
      className: className,
      section: section,
      examDate: examDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    )) {
      return 'Is class ke liye isi date aur time par already exam scheduled hai.';
    }

    final now = DateTime.now();
    final item = ExamScheduleModel(
      id: 'exam-${now.microsecondsSinceEpoch}',
      className: className,
      section: section,
      subject: subject,
      uploadedByName: uploadedByName,
      uploadedByRole: uploadedByRole,
      examDate: examDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      shiftLabel: shiftLabel,
      place: place,
      blockName: blockName,
      roomNumber: roomNumber,
      seatLabel: seatLabel,
      description: description,
      dateSheetName: dateSheetName,
      dateSheetPath: dateSheetPath,
      createdAt: now,
    );

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: item.id,
      data: item.toMap(),
    );
    schedules.add(item);
    schedules.sort((a, b) => a.examDate.compareTo(b.examDate));
    return null;
  }

  List<ExamScheduleModel> schedulesForClass({
    required String className,
    required String section,
  }) {
    return schedules
        .where(
          (item) =>
              item.className.trim() == className.trim() &&
              item.section.trim().toUpperCase() == section.trim().toUpperCase(),
        )
        .toList(growable: false);
  }
}
