import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/attendance_entry_model.dart';

class AttendanceService extends GetxService {
  static const _collection = 'attendance_entries';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<AttendanceEntryModel> attendanceEntries =
      <AttendanceEntryModel>[].obs;
  final RxBool isLoading = false.obs;
  Future<List<AttendanceEntryModel>>? _entriesLoadFuture;

  Future<List<AttendanceEntryModel>> loadEntries() async {
    final inFlight = _entriesLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _loadEntriesInternal();
    _entriesLoadFuture = future;
    return future;
  }

  Future<List<AttendanceEntryModel>> _loadEntriesInternal() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<AttendanceEntryModel>(
        path: _collection,
        fromMap: AttendanceEntryModel.fromMap,
      );

      if (fetched.isEmpty && attendanceEntries.isEmpty) {
        attendanceEntries.clear();
      } else {
        attendanceEntries.value = fetched
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      }

      return attendanceEntries.toList(growable: false);
    } finally {
      isLoading.value = false;
      _entriesLoadFuture = null;
    }
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

  /// Upserts one `attendance_entries` document per student in [roster].
  ///
  /// Document ID: `<studentUid>_<date>` (e.g. "abc123_2024-01-15").
  /// If a document already exists for that key, only `status` and `markedAt`
  /// are updated (merge: true), satisfying Requirement 4.3.
  Future<void> bulkMarkAttendance({
    required List<Map<String, dynamic>> roster,
    required String date,
    required Map<String, AttendanceStatus> statusMap,
  }) async {
    final now = DateTime.now();
    final futures = roster.map((student) {
      final uid = student['uid'] as String? ?? '';
      final docId = '${uid}_$date';
      final status = statusMap[uid] ?? AttendanceStatus.present;

      final data = <String, dynamic>{
        'studentName': student['name'] ?? '',
        'rollNumber': student['rollNumber'] ?? '',
        'className': student['className'] ?? '',
        'section': student['section'] ?? '',
        'email': student['email'] ?? '',
        'submittedAt': now.toIso8601String(),
        'markedAt': now.toIso8601String(),
        'status': status.name,
        'date': date,
      };

      return _store.setCollectionDocument(
        collectionPath: _collection,
        id: docId,
        data: data,
        merge: true,
      );
    });

    await Future.wait(futures);
  }
}
