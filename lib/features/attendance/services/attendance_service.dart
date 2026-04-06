import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/attendance_entry_model.dart';

class AttendanceService extends GetxService {
  static const _collection = 'attendance_entries';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<AttendanceEntryModel> attendanceEntries =
      <AttendanceEntryModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<List<AttendanceEntryModel>> loadEntries() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<AttendanceEntryModel>(
        path: _collection,
        fromMap: AttendanceEntryModel.fromMap,
      );

      if (fetched.isEmpty && attendanceEntries.isEmpty) {
        final seed = _seedEntries();
        for (final entry in seed) {
          await _store.setCollectionDocument(
            collectionPath: _collection,
            id: entry.id,
            data: entry.toMap(),
          );
        }
        attendanceEntries.value = seed;
      } else {
        attendanceEntries.value = fetched
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      }

      return attendanceEntries.toList(growable: false);
    } finally {
      isLoading.value = false;
    }
  }

  List<AttendanceEntryModel> _seedEntries() {
    return [
      AttendanceEntryModel(
        id: 'seed-1',
        studentName: 'Project Shaku',
        rollNumber: '03',
        className: '3',
        section: 'A',
        email: 'project.shaku@example.com',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 12)),
        status: AttendanceStatus.pending,
      ),
      AttendanceEntryModel(
        id: 'seed-2',
        studentName: 'Areeba Khan',
        rollNumber: '14',
        className: '3',
        section: 'A',
        email: 'areeba@example.com',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
        markedAt: DateTime.now().subtract(const Duration(days: 2, minutes: 20)),
        status: AttendanceStatus.present,
      ),
    ];
  }

  Future<void> submitAttendance({
    required String studentName,
    required String rollNumber,
    required String className,
    required String section,
    required String email,
    String? photoPath,
  }) async {
    final now = DateTime.now();
    final item = AttendanceEntryModel(
      id: now.microsecondsSinceEpoch.toString(),
      studentName: studentName,
      rollNumber: rollNumber,
      className: className,
      section: section,
      email: email,
      submittedAt: now,
      photoPath: photoPath,
      status: AttendanceStatus.pending,
    );

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: item.id,
      data: item.toMap(),
    );
    attendanceEntries.insert(0, item);
  }

  Future<void> updateAttendanceStatus(
    String id,
    AttendanceStatus status,
  ) async {
    final index = attendanceEntries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;

    final updated = attendanceEntries[index].copyWith(
      status: status,
      markedAt: DateTime.now(),
    );

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: id,
      data: updated.toMap(),
      merge: true,
    );
    attendanceEntries[index] = updated;
  }
}
