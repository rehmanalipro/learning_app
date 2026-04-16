import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_collection_service.dart';
import '../models/attendance_entry_model.dart';

class AttendanceService extends GetxService {
  static const _collection = 'attendance_entries';
  static const _reviewSeedPrefix = 'attendance_review_seeded_';
  static const _reviewStatusPrefix = 'attendance_review_status_';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final FirebaseService _firebaseService = FirebaseService();
  final RxList<AttendanceEntryModel> attendanceEntries =
      <AttendanceEntryModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<List<AttendanceEntryModel>>? _entriesLoadFuture;
  StreamSubscription<dynamic>? _entriesSubscription;
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.initialize();
  }

  @override
  void onClose() {
    _entriesSubscription?.cancel();
    super.onClose();
  }

  Future<List<AttendanceEntryModel>> loadEntries() async {
    final inFlight = _entriesLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _loadEntriesInternal();
    _entriesLoadFuture = future;
    return future;
  }

  Future<List<AttendanceEntryModel>> _loadEntriesInternal() async {
    try {
      if (_firebaseService.isAvailable) {
        await _ensureEntriesSubscription();
        await _processStudentReviewNotifications(
          previousById: {
            for (final entry in attendanceEntries) entry.id: entry,
          },
          currentEntries: attendanceEntries.toList(growable: false),
        );
        return attendanceEntries.toList(growable: false);
      }

      return await _loadEntriesFallback();
    } finally {
      _entriesLoadFuture = null;
    }
  }

  Future<void> _ensureEntriesSubscription() async {
    if (_entriesSubscription != null) return;

    isLoading.value = true;
    final completer = Completer<void>();

    _entriesSubscription = _firebaseService.firestore
        .collection(_collection)
        .snapshots()
        .listen(
          (snapshot) async {
            final previousById = {
              for (final entry in attendanceEntries) entry.id: entry,
            };
            final fetched = snapshot.docs
                .map((doc) => AttendanceEntryModel.fromMap(doc.id, doc.data()))
                .toList(growable: false)
              ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

            attendanceEntries.value = fetched;
            await _processStudentReviewNotifications(
              previousById: previousById,
              currentEntries: fetched,
            );

            isLoading.value = false;
            if (!completer.isCompleted) completer.complete();
          },
          onError: (error) {
            isLoading.value = false;
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
        );

    return completer.future;
  }

  Future<List<AttendanceEntryModel>> _loadEntriesFallback() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<AttendanceEntryModel>(
        path: _collection,
        fromMap: AttendanceEntryModel.fromMap,
      );

      attendanceEntries.value = fetched
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      await _processStudentReviewNotifications(
        previousById: const <String, AttendanceEntryModel>{},
        currentEntries: attendanceEntries.toList(growable: false),
      );

      return attendanceEntries.toList(growable: false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitAttendance({
    required String studentName,
    required String rollNumber,
    required String className,
    required String section,
    required String email,
    String? photoPath,
    String? notes,
  }) async {
    final now = DateTime.now();
    final studentUid = (_firebaseService.currentUser?.uid ?? '').trim();
    final normalizedSection = section.trim().toUpperCase();
    final dateKey = _dateKey(now);
    final entryId = _entryIdFor(
      studentUid: studentUid,
      email: email,
      rollNumber: rollNumber,
      className: className,
      section: normalizedSection,
      dateKey: dateKey,
    );

    AttendanceEntryModel? existing;
    final rawExisting = await _store.getRawDocument('$_collection/$entryId');
    if (rawExisting != null) {
      existing = AttendanceEntryModel.fromMap(entryId, rawExisting);
    }

    final trimmedNotes = notes?.trim();
    final hasTeacherReview =
        existing != null && existing.status != AttendanceStatus.pending;

    final item = AttendanceEntryModel(
      id: entryId,
      studentUid: studentUid,
      studentName: studentName.trim(),
      rollNumber: rollNumber.trim(),
      className: className.trim(),
      section: normalizedSection,
      email: email.trim().toLowerCase(),
      dateKey: dateKey,
      submittedAt: now,
      markedAt: hasTeacherReview ? existing.markedAt : null,
      photoPath: photoPath ?? existing?.photoPath,
      notes: (trimmedNotes?.isNotEmpty ?? false) ? trimmedNotes : existing?.notes,
      status: hasTeacherReview ? existing.status : AttendanceStatus.pending,
    );

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: item.id,
      data: item.toMap(),
      merge: true,
    );
    _upsertEntry(item);
    await _rememberCurrentStudentEntryStatus(item);
  }

  Future<void> updateAttendanceStatus(
    String id,
    AttendanceStatus status,
  ) async {
    final index = attendanceEntries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;

    final current = attendanceEntries[index];
    if (current.status == status && current.markedAt != null) return;

    final updated = current.copyWith(
      status: status,
      markedAt: DateTime.now(),
    );

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: id,
      data: updated.toMap(),
      merge: true,
    );
    _upsertEntry(updated);
  }

  /// Upserts one `attendance_entries` document per student in [roster].
  ///
  /// Document ID: `<studentUid>_<date>` when UID is available, otherwise a
  /// sanitized fallback key. Existing entries keep their original submit time
  /// and notes so teacher review and student requests stay aligned.
  Future<void> bulkMarkAttendance({
    required List<Map<String, dynamic>> roster,
    required String date,
    required Map<String, AttendanceStatus> statusMap,
  }) async {
    final now = DateTime.now();

    await Future.wait(
      roster.map((student) async {
        final uid = (student['uid'] as String? ?? '').trim();
        final className = (student['className'] as String? ?? '').trim();
        final section = (student['section'] as String? ?? '').trim().toUpperCase();
        final email = (student['email'] as String? ?? '').trim().toLowerCase();
        final rollNumber = (student['rollNumber'] as String? ?? '').trim();

        final entryId = _entryIdFor(
          studentUid: uid,
          email: email,
          rollNumber: rollNumber,
          className: className,
          section: section,
          dateKey: date,
        );
        final rawExisting = await _store.getRawDocument('$_collection/$entryId');
        final existing = rawExisting == null
            ? null
            : AttendanceEntryModel.fromMap(entryId, rawExisting);

        final status = statusMap[uid] ?? AttendanceStatus.present;
        final item = AttendanceEntryModel(
          id: entryId,
          studentUid: uid,
          studentName: (student['name'] as String? ?? '').trim(),
          rollNumber: rollNumber,
          className: className,
          section: section,
          email: email,
          dateKey: date,
          submittedAt: existing?.submittedAt ?? now,
          markedAt: now,
          photoPath: existing?.photoPath,
          notes: existing?.notes,
          status: status,
        );

        await _store.setCollectionDocument(
          collectionPath: _collection,
          id: item.id,
          data: item.toMap(),
          merge: true,
        );
        _upsertEntry(item);
      }),
    );
  }

  Future<void> _processStudentReviewNotifications({
    required Map<String, AttendanceEntryModel> previousById,
    required List<AttendanceEntryModel> currentEntries,
  }) async {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    final relevantEntries = currentEntries
        .where((entry) => _belongsToCurrentStudent(entry, user))
        .toList(growable: false)
      ..sort((a, b) {
        final markedA = a.markedAt ?? a.submittedAt;
        final markedB = b.markedAt ?? b.submittedAt;
        return markedB.compareTo(markedA);
      });

    final prefs = await _prefsInstance();
    final seedKey = '$_reviewSeedPrefix${user.uid}';
    final alreadySeeded = prefs.getBool(seedKey) ?? false;

    if (!alreadySeeded) {
      for (final entry in relevantEntries) {
        await prefs.setString(
          _reviewStatusKey(user.uid, entry.id),
          entry.status.name,
        );
      }
      await prefs.setBool(seedKey, true);
      return;
    }

    for (final entry in relevantEntries) {
      final statusKey = _reviewStatusKey(user.uid, entry.id);
      final previousStoredStatus =
          prefs.getString(statusKey) ?? previousById[entry.id]?.status.name;
      final shouldNotify =
          entry.markedAt != null &&
          entry.status != AttendanceStatus.pending &&
          previousStoredStatus != entry.status.name;

      if (shouldNotify) {
        await _showAttendanceReviewedNotification(entry);
      }

      await prefs.setString(statusKey, entry.status.name);
    }
  }

  Future<void> _rememberCurrentStudentEntryStatus(
    AttendanceEntryModel entry,
  ) async {
    final user = _firebaseService.currentUser;
    if (user == null || !_belongsToCurrentStudent(entry, user)) return;

    final prefs = await _prefsInstance();
    await prefs.setBool('$_reviewSeedPrefix${user.uid}', true);
    await prefs.setString(
      _reviewStatusKey(user.uid, entry.id),
      entry.status.name,
    );
  }

  Future<void> _showAttendanceReviewedNotification(
    AttendanceEntryModel entry,
  ) async {
    final statusLabel = entry.status == AttendanceStatus.present
        ? 'Present'
        : 'Absent';
    final title = 'Attendance Reviewed';
    final body =
        'Your attendance for ${_humanDate(entry)} was marked $statusLabel.';

    try {
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().showLocalAlert(
          title: title,
          body: body,
          data: {
            'type': 'attendance',
            'entryId': entry.id,
            'status': entry.status.name,
          },
        );
        return;
      }
    } catch (_) {}

    if (Get.context != null) {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool _belongsToCurrentStudent(
    AttendanceEntryModel entry,
    User user,
  ) {
    final uid = user.uid.trim();
    final email = (user.email ?? '').trim().toLowerCase();

    if (entry.studentUid.trim().isNotEmpty && entry.studentUid == uid) {
      return true;
    }

    return email.isNotEmpty && entry.email.trim().toLowerCase() == email;
  }

  Future<SharedPreferences> _prefsInstance() async {
    final existing = _prefs;
    if (existing != null) return existing;
    final created = await SharedPreferences.getInstance();
    _prefs = created;
    return created;
  }

  String _reviewStatusKey(String uid, String entryId) {
    return '$_reviewStatusPrefix${uid}_$entryId';
  }

  void _upsertEntry(AttendanceEntryModel item) {
    final next = attendanceEntries.toList(growable: true);
    final index = next.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      next.add(item);
    } else {
      next[index] = item;
    }
    next.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    attendanceEntries.value = next;
  }

  String _dateKey(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _entryIdFor({
    required String studentUid,
    required String email,
    required String rollNumber,
    required String className,
    required String section,
    required String dateKey,
  }) {
    final identity = studentUid.isNotEmpty
        ? studentUid
        : [
            _slug(email),
            _slug(rollNumber),
            _slug(className),
            _slug(section),
          ].join('_');
    return '${identity}_$dateKey';
  }

  String _slug(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'unknown';
    final sanitized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _humanDate(AttendanceEntryModel entry) {
    final source = entry.markedAt ?? entry.submittedAt;
    final day = source.day.toString().padLeft(2, '0');
    final month = source.month.toString().padLeft(2, '0');
    return '$day/$month/${source.year}';
  }
}
