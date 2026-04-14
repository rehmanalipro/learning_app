import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_collection_service.dart';
import '../models/teacher_assignment_model.dart';
import '../models/teacher_profile_model.dart';
import 'teacher_assignment_service.dart';

class TeacherProfileService extends GetxService {
  static const _collection = 'teacher_profiles';

  final FirebaseService _firebaseService = FirebaseService();
  final FirestoreCollectionService _store = FirestoreCollectionService();
  final TeacherAssignmentService _assignmentService =
      Get.find<TeacherAssignmentService>();

  final RxList<TeacherProfileModel> teacherProfiles =
      <TeacherProfileModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.initialize();
  }

  String createProfileId() {
    return _firebaseService.firestore.collection(_collection).doc().id;
  }

  String normalizeEmployeeId(String value) {
    return value.trim().toUpperCase();
  }

  String normalizeUserId(String value) {
    return value.trim().toLowerCase();
  }

  Future<List<TeacherProfileModel>> loadAll() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<TeacherProfileModel>(
        path: _collection,
        fromMap: TeacherProfileModel.fromMap,
      );
      fetched.sort(_compareProfiles);
      teacherProfiles.assignAll(fetched);
      return teacherProfiles.toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<TeacherProfileModel?> getById(String id) async {
    final existing = teacherProfiles.firstWhereOrNull((item) => item.id == id);
    if (existing != null) return existing;
    return _store.getDocument<TeacherProfileModel>(
      path: '$_collection/$id',
      fromMap: TeacherProfileModel.fromMap,
    );
  }

  Future<void> upsertTeacherProfile(TeacherProfileModel profile) async {
    final now = DateTime.now().toIso8601String();
    final normalized = profile.copyWith(
      teacherEmail: profile.teacherEmail.trim().toLowerCase(),
      employeeId: normalizeEmployeeId(profile.employeeId),
      generatedUserId: profile.generatedUserId.trim(),
      updatedAt: now,
      createdAt: profile.createdAt.isEmpty ? now : profile.createdAt,
    );

    if (normalized.employeeId.trim().isNotEmpty) {
      final employeeDuplicate = await _firebaseService.firestore
          .collection(_collection)
          .where('employeeId', isEqualTo: normalized.employeeId)
          .limit(5)
          .get();
      final hasEmployeeDuplicate = employeeDuplicate.docs.any(
        (doc) => doc.id != normalized.id,
      );
      if (hasEmployeeDuplicate) {
        throw Exception(
          'This employee ID already exists. Please use a unique employee ID.',
        );
      }
    }

    if (normalized.teacherEmail.trim().isNotEmpty) {
      final emailDuplicate = await _firebaseService.firestore
          .collection(_collection)
          .where('teacherEmail', isEqualTo: normalized.teacherEmail.trim())
          .limit(5)
          .get();
      final hasEmailDuplicate = emailDuplicate.docs.any(
        (doc) => doc.id != normalized.id,
      );
      if (hasEmailDuplicate) {
        throw Exception(
          'This teacher email already exists. Please use a unique email.',
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
      await _upsertTeacherAssignment(normalized);
    }

    final index = teacherProfiles.indexWhere((item) => item.id == normalized.id);
    if (index == -1) {
      teacherProfiles.add(normalized);
    } else {
      teacherProfiles[index] = normalized;
    }
    teacherProfiles.sort(_compareProfiles);
  }

  Future<void> linkTeacherAccount({
    required String profileId,
    required String uid,
    required String email,
    required String generatedUserId,
    required String issuedAt,
  }) async {
    final profile = await getById(profileId);
    if (profile == null) {
      throw Exception('Teacher record not found.');
    }

    final updated = profile.copyWith(
      teacherEmail: profile.teacherEmail.trim().isEmpty
          ? email.trim().toLowerCase()
          : profile.teacherEmail.trim().toLowerCase(),
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
    await _upsertTeacherAssignment(updated);

    final index = teacherProfiles.indexWhere((item) => item.id == profileId);
    if (index == -1) {
      teacherProfiles.add(updated);
    } else {
      teacherProfiles[index] = updated;
    }
    teacherProfiles.sort(_compareProfiles);
  }

  Future<void> _upsertTeacherAssignment(TeacherProfileModel profile) async {
    await _assignmentService.upsertAssignment(
      TeacherAssignmentModel(
        id: profile.id,
        teacherUid: profile.linkedUserUid,
        teacherProfileId: profile.id,
        teacherName: profile.fullName,
        className: profile.className,
        section: profile.section,
        subject: profile.subject,
        session: '',
        isClassTeacher: profile.isClassTeacher,
        isActive: profile.status.toLowerCase() == 'active',
        createdAt: profile.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  int _compareProfiles(TeacherProfileModel a, TeacherProfileModel b) {
    final classA = int.tryParse(a.className.trim());
    final classB = int.tryParse(b.className.trim());
    if (classA != null && classB != null && classA != classB) {
      return classA.compareTo(classB);
    }
    final classCompare = a.className.trim().compareTo(b.className.trim());
    if (classCompare != 0) return classCompare;

    final sectionCompare = a.section.trim().toLowerCase().compareTo(
      b.section.trim().toLowerCase(),
    );
    if (sectionCompare != 0) return sectionCompare;

    final subjectCompare = a.subject.trim().toLowerCase().compareTo(
      b.subject.trim().toLowerCase(),
    );
    if (subjectCompare != 0) return subjectCompare;

    return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  }
}
