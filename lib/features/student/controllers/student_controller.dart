import 'package:get/get.dart';

import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentController extends GetxController {
  final StudentService _service = Get.find<StudentService>();

  RxList<StudentModel> get students => _service.students;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }

  Future<void> loadStudents() => _service.loadStudents();

  Future<void> addStudent(StudentModel student) => _service.addStudent(student);

  Future<void> updateStudent(StudentModel student) =>
      _service.updateStudent(student);

  Future<void> removeStudent(String id) => _service.removeStudent(id);
}
