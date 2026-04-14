import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_collection_service.dart';
import '../models/student_profile_model.dart';

class StudentProfileService extends GetxService {
  static const _collection = 'student_profiles';

  final FirebaseService _firebaseService = FirebaseService();
  final FirestoreCollectionService _store = FirestoreCollectionService();

  final RxList<StudentProfileModel> studentProfiles =
      <StudentProfileModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.initialize();
  }

  String createProfileId() {
    return _firebaseService.firestore.collection(_collection).doc().id;
  }

  String normalizeAdmissionNo(String value) {
    return value.trim().toUpperCase();
  }

  String normalizeUserId(String value) {
    return value.trim().toLowerCase();
  }

  String normalizeDate(String value) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return value.trim();
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  Future<List<StudentProfileModel>> loadAll() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<StudentProfileModel>(
        path: _collection,
        fromMap: StudentProfileModel.fromMap,
      );
      fetched.sort(_compareProfiles);
      studentProfiles.assignAll(fetched);
      return studentProfiles.toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<StudentProfileModel>> loadByClassSection({
    String? className,
    String? section,
  }) async {
    final all = await loadAll();
    return all
        .where((item) {
          final classMatches =
              className == null ||
              className.isEmpty ||
              className == 'All' ||
              item.className == className;
          final sectionMatches =
              section == null ||
              section.isEmpty ||
              section == 'All' ||
              item.section == section;
          return classMatches && sectionMatches;
        })
        .toList(growable: false);
  }

  Future<StudentProfileModel?> getById(String id) async {
    final existing = studentProfiles.firstWhereOrNull((item) => item.id == id);
    if (existing != null) return existing;
    return _store.getDocument<StudentProfileModel>(
      path: '$_collection/$id',
      fromMap: StudentProfileModel.fromMap,
    );
  }

  Future<StudentProfileModel?> findForAdmissionLink({
    required String admissionNo,
    required String dateOfBirth,
  }) async {
    final normalizedAdmission = normalizeAdmissionNo(admissionNo);
    final normalizedDob = normalizeDate(dateOfBirth);

    final snapshot = await _firebaseService.firestore
        .collection(_collection)
        .where('admissionNo', isEqualTo: normalizedAdmission)
        .get();

    final matched = snapshot.docs.firstWhereOrNull((doc) {
      final storedDob = normalizeDate(
        doc.data()['dateOfBirth'] as String? ?? '',
      );
      return storedDob == normalizedDob;
    });
    if (matched == null) return null;
    return StudentProfileModel.fromMap(matched.id, matched.data());
  }

  Future<void> upsertStudentProfile(StudentProfileModel profile) async {
    final now = DateTime.now().toIso8601String();
    final normalized = profile.copyWith(
      admissionNo: normalizeAdmissionNo(profile.admissionNo),
      dateOfBirth: normalizeDate(profile.dateOfBirth),
      studentEmail: profile.studentEmail.trim().toLowerCase(),
      generatedUserId: profile.generatedUserId.trim(),
      updatedAt: now,
      createdAt: profile.createdAt.isEmpty ? now : profile.createdAt,
    );

    final duplicate = await _firebaseService.firestore
        .collection(_collection)
        .where('admissionNo', isEqualTo: normalized.admissionNo)
        .limit(5)
        .get();
    final hasDuplicate = duplicate.docs.any((doc) => doc.id != normalized.id);
    if (hasDuplicate) {
      throw Exception(
        'This admission number already exists. Please use a unique admission number.',
      );
    }

    if (normalized.rollNumber.trim().isNotEmpty) {
      final rollDuplicate = await _firebaseService.firestore
          .collection(_collection)
          .where('rollNumber', isEqualTo: normalized.rollNumber.trim())
          .limit(5)
          .get();
      final hasRollDuplicate = rollDuplicate.docs.any(
        (doc) => doc.id != normalized.id,
      );
      if (hasRollDuplicate) {
        throw Exception(
          'This roll number already exists. Please use a unique roll number.',
        );
      }
    }

    if (normalized.studentEmail.trim().isNotEmpty) {
      final emailDuplicate = await _firebaseService.firestore
          .collection(_collection)
          .where('studentEmail', isEqualTo: normalized.studentEmail.trim())
          .limit(5)
          .get();
      final hasEmailDuplicate = emailDuplicate.docs.any(
        (doc) => doc.id != normalized.id,
      );
      if (hasEmailDuplicate) {
        throw Exception(
          'This student email already exists. Please use a unique email.',
        );
      }
    }

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: normalized.id,
      data: normalized.toMap(),
      merge: true,
    );

    if (normalized.isLinked && normalized.linkedUserEmail.trim().isNotEmpty) {
      await _firebaseService.updateUser(
        normalized.linkedUserUid,
        normalized.toLinkedUserMap(
          uid: normalized.linkedUserUid,
          email: normalized.linkedUserEmail,
        ),
      );
    }

    final index = studentProfiles.indexWhere(
      (item) => item.id == normalized.id,
    );
    if (index == -1) {
      studentProfiles.add(normalized);
    } else {
      studentProfiles[index] = normalized;
    }
    studentProfiles.sort(_compareProfiles);
  }

  Future<void> linkStudentAccount({
    required String profileId,
    required String uid,
    required String email,
    required String generatedUserId,
    required String issuedAt,
  }) async {
    final profile = await getById(profileId);
    if (profile == null) {
      throw Exception('Admission record not found.');
    }

    final updated = profile.copyWith(
      studentEmail: profile.studentEmail.trim().isEmpty
          ? email.trim().toLowerCase()
          : profile.studentEmail.trim().toLowerCase(),
      generatedUserId: generatedUserId.trim(),
      linkedUserUid: uid,
      linkedUserEmail: email.trim().toLowerCase(),
      credentialsIssuedAt: issuedAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: profileId,
      data: updated.toMap(),
      merge: true,
    );

    final index = studentProfiles.indexWhere((item) => item.id == profileId);
    if (index == -1) {
      studentProfiles.add(updated);
    } else {
      studentProfiles[index] = updated;
    }
    studentProfiles.sort(_compareProfiles);
  }

  int _compareProfiles(StudentProfileModel a, StudentProfileModel b) {
    final classA = int.tryParse(a.className.trim());
    final classB = int.tryParse(b.className.trim());
    if (classA != null && classB != null && classA != classB) {
      return classA.compareTo(classB);
    }
    if (a.className.trim() != b.className.trim()) {
      return a.className.trim().compareTo(b.className.trim());
    }

    final sectionCompare = a.section.trim().toLowerCase().compareTo(
      b.section.trim().toLowerCase(),
    );
    if (sectionCompare != 0) return sectionCompare;

    final rollA = a.rollNumber.trim();
    final rollB = b.rollNumber.trim();
    if (rollA.isNotEmpty && rollB.isNotEmpty) {
      final numberA = int.tryParse(rollA);
      final numberB = int.tryParse(rollB);
      if (numberA != null && numberB != null) {
        return numberA.compareTo(numberB);
      }
      return rollA.toLowerCase().compareTo(rollB.toLowerCase());
    }
    return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  }
}
