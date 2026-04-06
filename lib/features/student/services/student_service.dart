import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/student_model.dart';

class StudentService extends GetxService {
  static const _collection = 'students';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<StudentModel> students = <StudentModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<List<StudentModel>> loadStudents() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<StudentModel>(
        path: _collection,
        fromMap: StudentModel.fromMap,
      );

      if (fetched.isEmpty && students.isEmpty) {
        final seed = <StudentModel>[
          StudentModel(id: 's1', name: 'Ali Khan', className: '3'),
          StudentModel(id: 's2', name: 'Sara Ahmed', className: '3'),
          StudentModel(id: 's3', name: 'Bilal Iqbal', className: '4'),
        ];
        for (final student in seed) {
          await _store.setCollectionDocument(
            collectionPath: _collection,
            id: student.id,
            data: student.toMap(),
          );
        }
        students.value = seed;
      } else {
        students.value = fetched;
      }
      return students.toList(growable: false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addStudent(StudentModel student) async {
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: student.id,
      data: student.toMap(),
    );
    students.add(student);
  }

  Future<void> updateStudent(StudentModel student) async {
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: student.id,
      data: student.toMap(),
      merge: true,
    );
    final index = students.indexWhere((item) => item.id == student.id);
    if (index != -1) {
      students[index] = student;
    }
  }

  Future<void> removeStudent(String id) async {
    await _store.deleteCollectionDocument(collectionPath: _collection, id: id);
    students.removeWhere((item) => item.id == id);
  }
}
