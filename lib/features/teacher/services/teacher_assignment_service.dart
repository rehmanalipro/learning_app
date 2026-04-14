import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_collection_service.dart';
import '../models/teacher_assignment_model.dart';

class TeacherAssignmentService extends GetxService {
  static const _collection = 'teacher_assignments';

  final FirebaseService _firebaseService = FirebaseService();
  final FirestoreCollectionService _store = FirestoreCollectionService();

  final RxList<TeacherAssignmentModel> assignments =
      <TeacherAssignmentModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.initialize();
  }

  Future<List<TeacherAssignmentModel>> loadAll() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<TeacherAssignmentModel>(
        path: _collection,
        fromMap: TeacherAssignmentModel.fromMap,
      );
      assignments.assignAll(fetched);
      return assignments.toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<TeacherAssignmentModel>> loadForTeacher(String teacherUid) async {
    final all = await loadAll();
    return all
        .where((item) => item.teacherUid == teacherUid && item.isActive)
        .toList(growable: false);
  }

  Future<void> upsertAssignment(TeacherAssignmentModel assignment) async {
    final now = DateTime.now().toIso8601String();
    final normalized = assignment.copyWith(
      createdAt: assignment.createdAt.isEmpty ? now : assignment.createdAt,
      updatedAt: now,
    );

    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: normalized.id,
      data: normalized.toMap(),
      merge: true,
    );

    final index = assignments.indexWhere((item) => item.id == normalized.id);
    if (index == -1) {
      assignments.add(normalized);
    } else {
      assignments[index] = normalized;
    }
  }
}
