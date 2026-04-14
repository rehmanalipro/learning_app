import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/student_model.dart';

class StudentService extends GetxService {
  static const _collection = 'students';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<StudentModel> students = <StudentModel>[].obs;
  final RxBool isLoading = false.obs;
  Future<List<StudentModel>>? _studentsLoadFuture;

  Future<List<StudentModel>> loadStudents() async {
    final inFlight = _studentsLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _loadStudentsInternal();
    _studentsLoadFuture = future;
    return future;
  }

  Future<List<StudentModel>> _loadStudentsInternal() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<StudentModel>(
        path: _collection,
        fromMap: StudentModel.fromMap,
      );
      fetched.sort(_compareStudents);
      students.value = fetched;
      return students.toList(growable: false);
    } finally {
      isLoading.value = false;
      _studentsLoadFuture = null;
    }
  }

  Future<void> addStudent(StudentModel student) async {
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: student.id,
      data: student.toMap(),
    );
    students.add(student);
    students.sort(_compareStudents);
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
      students.sort(_compareStudents);
    }
  }

  Future<void> removeStudent(String id) async {
    await _store.deleteCollectionDocument(collectionPath: _collection, id: id);
    students.removeWhere((item) => item.id == id);
  }

  int _compareStudents(StudentModel a, StudentModel b) {
    final classA = int.tryParse(a.className.trim());
    final classB = int.tryParse(b.className.trim());
    if (classA != null && classB != null && classA != classB) {
      return classA.compareTo(classB);
    }
    if (a.className != b.className) {
      return a.className.compareTo(b.className);
    }

    final sectionCompare = a.section.toLowerCase().compareTo(
      b.section.toLowerCase(),
    );
    if (sectionCompare != 0) return sectionCompare;

    final rollA = int.tryParse(a.rollNumber.trim());
    final rollB = int.tryParse(b.rollNumber.trim());
    if (rollA != null && rollB != null && rollA != rollB) {
      return rollA.compareTo(rollB);
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
