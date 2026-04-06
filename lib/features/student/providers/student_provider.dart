import 'package:get/get.dart';

import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentProvider extends GetxController {
  late final StudentService _service;
  RxList<StudentModel> get students => _service.students;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<StudentService>();
    loadStudents();
  }

  Future<void> loadStudents() => _service.loadStudents();

  Future<void> addStudent(StudentModel student) => _service.addStudent(student);

  Future<void> updateStudent(StudentModel updated) =>
      _service.updateStudent(updated);

  Future<void> removeStudent(String id) => _service.removeStudent(id);
}
