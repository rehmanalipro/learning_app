import 'package:get/get.dart';

import 'firebase_service.dart';

/// Loads and exposes the list of students belonging to a specific class+section.
///
/// Prefers role-based `students` documents and falls back to
/// principal-managed `student_profiles` records for older data.
class ClassRosterService extends GetxService {
  final FirebaseService _firebaseService = FirebaseService();

  /// The currently loaded roster of students.
  final RxList<Map<String, dynamic>> roster = <Map<String, dynamic>>[].obs;

  /// Whether a roster query is in progress.
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.initialize();
  }

  /// Queries the master student roster for [className] and [section], then
  /// populates [roster].
  Future<void> loadRoster({
    required String className,
    required String section,
  }) async {
    isLoading.value = true;
    try {
      try {
        final studentsSnapshot = await _firebaseService.firestore
            .collection('students')
            .get();

        if (studentsSnapshot.docs.isNotEmpty) {
          final structuredRoster = studentsSnapshot.docs
              .map((doc) {
                final data = doc.data();
                return <String, dynamic>{
                  'uid': data['authUid'] ?? doc.id,
                  'accountDocId': doc.id,
                  'studentProfileId':
                      data['linkedStudentProfileId'] ?? data['studentProfileId'] ?? '',
                  'linkedUserUid': data['authUid'] ?? doc.id,
                  'userId': data['userId'] ?? '',
                  'name': data['name'] ?? '',
                  'email': data['email'] ?? '',
                  'admissionNo': data['admissionNo'] ?? '',
                  'rollNumber': data['rollNumber'] ?? '',
                  'className': data['className'] ?? '',
                  'section': data['section'] ?? '',
                  'programName': data['programName'] ?? '',
                  'status': data['status'] ?? 'active',
                };
              })
              .where((student) {
                final sameClass =
                    (student['className'] as String? ?? '') == className;
                final sameSection =
                    (student['section'] as String? ?? '') == section;
                final status = (student['status'] as String? ?? 'active')
                    .toLowerCase();
                return sameClass && sameSection && status == 'active';
              })
              .toList();

          if (structuredRoster.isNotEmpty) {
            roster.value = structuredRoster..sort(_compareStudents);
            return;
          }
        }
      } catch (_) {}

      final legacySnapshot = await _firebaseService.firestore
          .collection('student_profiles')
          .get();

      roster.value =
          legacySnapshot.docs
              .map((doc) {
                final data = doc.data();
                return <String, dynamic>{
                  'uid':
                      (data['linkedUserUid'] as String? ?? '').trim().isEmpty
                          ? doc.id
                          : (data['linkedUserUid'] as String).trim(),
                  'studentProfileId': doc.id,
                  'linkedUserUid': data['linkedUserUid'] ?? '',
                  'userId': data['generatedUserId'] ?? '',
                  'name': data['fullName'] ?? data['name'] ?? '',
                  'email': data['studentEmail'] ?? data['linkedUserEmail'] ?? '',
                  'admissionNo': data['admissionNo'] ?? '',
                  'rollNumber': data['rollNumber'] ?? '',
                  'className': data['className'] ?? '',
                  'section': data['section'] ?? '',
                  'programName': data['programName'] ?? '',
                  'status': data['status'] ?? 'active',
                };
              })
              .where((student) {
                final sameClass =
                    (student['className'] as String? ?? '') == className;
                final sameSection =
                    (student['section'] as String? ?? '') == section;
                final status = (student['status'] as String? ?? 'active')
                    .toLowerCase();
                return sameClass && sameSection && status == 'active';
              })
              .toList()
            ..sort(_compareStudents);
    } finally {
      isLoading.value = false;
    }
  }

  int _compareStudents(Map<String, dynamic> a, Map<String, dynamic> b) {
    final rollA = (a['rollNumber'] as String? ?? '').trim();
    final rollB = (b['rollNumber'] as String? ?? '').trim();
    if (rollA.isNotEmpty && rollB.isNotEmpty) {
      final numberA = int.tryParse(rollA);
      final numberB = int.tryParse(rollB);
      if (numberA != null && numberB != null) {
        return numberA.compareTo(numberB);
      }
      return rollA.toLowerCase().compareTo(rollB.toLowerCase());
    }
    if (rollA.isNotEmpty || rollB.isNotEmpty) {
      return rollA.isNotEmpty ? -1 : 1;
    }

    final nameA = (a['name'] as String? ?? '').toLowerCase();
    final nameB = (b['name'] as String? ?? '').toLowerCase();
    return nameA.compareTo(nameB);
  }

  /// Clears the current roster without triggering a new query.
  void clearRoster() {
    roster.clear();
  }
}
