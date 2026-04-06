import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/teacher_model.dart';

class TeacherService extends GetxService {
  static const _collection = 'teachers';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<List<TeacherModel>> loadTeachers() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<TeacherModel>(
        path: _collection,
        fromMap: TeacherModel.fromMap,
      );

      if (fetched.isEmpty && teachers.isEmpty) {
        final seed = <TeacherModel>[
          TeacherModel(id: 't1', name: 'Teacher A', subject: 'Science'),
          TeacherModel(id: 't2', name: 'Teacher B', subject: 'English'),
        ];
        for (final teacher in seed) {
          await _store.setCollectionDocument(
            collectionPath: _collection,
            id: teacher.id,
            data: teacher.toMap(),
          );
        }
        teachers.value = seed;
      } else {
        teachers.value = fetched;
      }

      return teachers.toList(growable: false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTeacher(TeacherModel teacher) async {
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: teacher.id,
      data: teacher.toMap(),
    );
    teachers.add(teacher);
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: teacher.id,
      data: teacher.toMap(),
      merge: true,
    );
    final index = teachers.indexWhere((item) => item.id == teacher.id);
    if (index == -1) {
      teachers.add(teacher);
      return;
    }
    teachers[index] = teacher;
  }

  Future<void> removeTeacher(String id) async {
    await _store.deleteCollectionDocument(collectionPath: _collection, id: id);
    teachers.removeWhere((item) => item.id == id);
  }
}
